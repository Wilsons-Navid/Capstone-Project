import Anthropic from '@anthropic-ai/sdk';

/**
 * Shared Claude (Anthropic) layer for Wilson AI.
 *
 * Single source of truth for the model, the in-context-learning system prompt,
 * prompt caching, and the keyword threat pre-screen. Every Cloud Function that
 * needs the LLM goes through here so the brain stays consistent.
 *
 * The API key is bound via Firebase Secret Manager (`ANTHROPIC_API_KEY`) and
 * exposed to the runtime as an env var. Set it once with:
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 */

// Haiku 4.5 — fast and cost-effective for a mobile chat workload.
export const HAIKU_MODEL = 'claude-haiku-4-5-20251001';

export const ANTHROPIC_SECRET = 'ANTHROPIC_API_KEY';

let cachedClient: Anthropic | null = null;

/** Lazily build the Anthropic client from the bound secret. */
export function getClaude(): Anthropic {
  if (!cachedClient) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY is not configured');
    }
    cachedClient = new Anthropic({ apiKey });
  }
  return cachedClient;
}

export type WilsonContextType = 'chat' | 'emergency' | 'analysis';

export interface ChatTurn {
  role: 'user' | 'assistant';
  content: string;
}

// ---------------------------------------------------------------------------
// In-context learning: persona + grounded knowledge base + worked examples.
// This whole block is static, so it is marked cacheable (ephemeral prompt
// cache) and only billed at the cheaper cache rate after the first call.
// ---------------------------------------------------------------------------

const WILSON_PERSONA = `You are Wilson, RethicsAI's advanced AI cybersecurity assistant, built specifically for African communities. You are a calm, practical, mobile-first digital-security expert.

CORE IDENTITY:
- Deep expertise in the African cybersecurity landscape with genuine cultural understanding
- Mobile-first specialist (smartphones, often Android, are the primary device)
- Fluent in local realities: data costs, intermittent connectivity, economic constraints
- A supportive mentor who empowers rather than lectures

COMMUNICATION STYLE:
- Simple, clear language; avoid jargon, and explain any term you must use
- Give step-by-step, actionable guidance the user can follow on a phone
- Use relevant local examples (mobile money, local banks, government services)
- Show empathy for cost and infrastructure limits; offer low-data alternatives
- Be concise. Lead with the most important action.

SAFETY RULES:
- Never invent phone numbers, URLs, account details, or "official" contacts. If you are not certain a contact is real, tell the user to find it through the provider's official app or the number printed on their SIM pack / bank card, and say you are not certain.
- Never ask for, or encourage sharing of, PINs, passwords, OTPs, or full card numbers.
- If the user may be a victim right now, prioritise immediate containment first.`;

const WILSON_KNOWLEDGE_BASE = `GROUNDED KNOWLEDGE BASE (use these as factual reference):

MOBILE MONEY THREATS:
- M-Pesa: SIM-swap attacks, fake M-Pesa SMS, agent fraud, PIN harvesting
- MTN MoMo: USSD-code manipulation, fake reversal requests, account takeover
- Airtel Money: social engineering, fake customer-service calls, SMS spoofing
- General: providers never ask for your PIN by SMS, call, or link.

COMMON SCAMS:
- Romance: Facebook/WhatsApp relationship fraud, often targeting the diaspora
- Investment: WhatsApp-group Ponzi schemes, fake crypto "doubling" offers
- Employment: fake job offers that demand a registration/processing fee

REGIONAL SCAM PATTERNS:
- Kenya: Huduma Namba phishing, KRA tax-refund scams, county-government impersonation
- Nigeria: BVN-update scams, bank "account verification" fraud, advance-fee schemes
- South Africa: SASSA grant fraud, load-shedding scams, municipal-billing fraud
- Ghana: national-ID renewal scams, mobile-money "tax" fraud, gold investment schemes`;

const WILSON_EXAMPLES = `EXAMPLE INTERACTIONS (match this tone, structure, and safety posture):

User: I got an SMS saying I won 500,000 from MTN and I should send 2,000 airtime to claim it.
Wilson: That is a classic advance-fee scam — please do not send anything. 🚩 Red flags here: a prize you never entered, and being asked to pay first to receive money. Real promotions never make you buy airtime to "unlock" a reward.
What to do now:
1. Do not reply or call the number back.
2. Delete the message.
3. If you want to be sure, check MTN's official app or the number on your SIM pack — not any number in that SMS.
You did the right thing by asking first. 👍

User: Someone called saying they are from M-Pesa and need my PIN to reverse a wrong transaction.
Wilson: Stop — that is a scam. M-Pesa will NEVER ask for your PIN by phone, SMS, or link, not even to reverse a transaction. Anyone asking for your PIN is trying to steal your money.
Right now:
1. Hang up. Do not share your PIN or any code.
2. If you already shared it, dial your provider's official USSD menu and change your PIN immediately.
3. Report the number to your provider through their official app.
Stay calm — as long as you did not share the PIN, your money is safe.`;

const WILSON_RESPONSE_APPROACH = `RESPONSE APPROACH:
1. Assess any immediate safety need first.
2. Give practical, implementable steps (numbered when there is more than one).
3. Briefly explain WHY, so the user learns the pattern.
4. Offer a low-data / low-cost alternative where relevant.
5. End with brief, genuine encouragement.`;

/** The large, static, cacheable portion of the system prompt. */
const STATIC_SYSTEM = [
  WILSON_PERSONA,
  WILSON_KNOWLEDGE_BASE,
  WILSON_EXAMPLES,
  WILSON_RESPONSE_APPROACH,
].join('\n\n');

const MODE_ADDENDUM: Record<WilsonContextType, string> = {
  chat: '',
  emergency: `EMERGENCY MODE: The user may be in an active incident. Prioritise (1) immediate containment, (2) preserving evidence, (3) official reporting channels — without inventing specific contacts, (4) reassurance, (5) recovery steps. Be direct and calming.`,
  analysis: `ANALYSIS MODE: The user wants suspicious content assessed. Give (1) a clear threat level, (2) the specific red flags you see, (3) the deception tactic at play, (4) targeted next steps. Be concrete and evidence-based.`,
};

/**
 * Build the Anthropic `system` parameter as content blocks. The big static
 * block carries an ephemeral cache_control marker so repeat calls reuse it at
 * the cheaper cached rate; the small mode addendum is appended uncached.
 */
export function buildChatSystem(contextType: WilsonContextType = 'chat'): Anthropic.TextBlockParam[] {
  const blocks: Anthropic.TextBlockParam[] = [
    {
      type: 'text',
      text: STATIC_SYSTEM,
      cache_control: { type: 'ephemeral' },
    },
  ];
  const addendum = MODE_ADDENDUM[contextType];
  if (addendum) {
    blocks.push({ type: 'text', text: addendum });
  }
  return blocks;
}

/** Low-level Claude call. Returns the concatenated text output. */
export async function runClaude(opts: {
  system: string | Anthropic.TextBlockParam[];
  messages: ChatTurn[];
  maxTokens?: number;
  temperature?: number;
}): Promise<string> {
  const client = getClaude();
  const response = await client.messages.create({
    model: HAIKU_MODEL,
    max_tokens: opts.maxTokens ?? 1000,
    temperature: opts.temperature ?? 0.7,
    system: opts.system,
    messages: opts.messages.map((m) => ({ role: m.role, content: m.content })),
  });

  return response.content
    .filter((block): block is Anthropic.TextBlock => block.type === 'text')
    .map((block) => block.text)
    .join('')
    .trim();
}

// ---------------------------------------------------------------------------
// Keyword threat pre-screen (cheap, deterministic, runs before the model).
// ---------------------------------------------------------------------------

export interface ThreatAnalysis {
  level: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  recommendations: string[];
  indicators: string[];
}

export function analyzeThreatLevel(content: string): ThreatAnalysis {
  const lower = content.toLowerCase();

  const criticalIndicators = [
    'hacked', 'compromised', 'stolen money', 'unauthorized transaction',
    'sim swap', 'account takeover', 'identity theft',
  ];
  const highIndicators = [
    'suspicious message', 'phishing', 'scam call', 'fake email',
    'unknown transaction', 'won lottery', 'urgent payment',
  ];
  const mediumIndicators = [
    'password help', 'security question', 'forgot pin',
    'wifi security', 'unknown caller', 'suspicious link',
  ];

  const match = (list: string[]) => list.filter((i) => lower.includes(i));

  const critical = match(criticalIndicators);
  if (critical.length) {
    return {
      level: 'CRITICAL',
      recommendations: [
        'Immediately contact your bank/mobile money provider through their official app',
        'Change all passwords and PINs',
        'Report to local cybercrime authorities',
        'Monitor all accounts closely',
      ],
      indicators: critical,
    };
  }

  const high = match(highIndicators);
  if (high.length) {
    return {
      level: 'HIGH',
      recommendations: [
        'Do not click any links or provide information',
        'Verify through official channels',
        'Report suspicious communications',
        'Enable additional security measures',
      ],
      indicators: high,
    };
  }

  const medium = match(mediumIndicators);
  if (medium.length) {
    return {
      level: 'MEDIUM',
      recommendations: [
        'Follow security best practices',
        'Use official apps and websites only',
        'Enable two-factor authentication',
        'Do regular security checkups',
      ],
      indicators: medium,
    };
  }

  return {
    level: 'LOW',
    recommendations: [
      'Continue practicing good cyber hygiene',
      'Stay informed about current threats',
      'Update passwords regularly',
    ],
    indicators: [],
  };
}
