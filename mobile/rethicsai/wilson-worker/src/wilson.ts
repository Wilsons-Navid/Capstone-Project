/**
 * Wilson AI — Claude (Anthropic) inference layer for the Cloudflare Worker.
 *
 * Self-contained (no SDK): calls the Anthropic REST API directly via fetch,
 * which keeps the edge bundle tiny and the cold path fast. Mirrors the
 * in-context-learning system prompt used by the (now superseded) Firebase
 * Functions implementation.
 */

import { getResources } from './resources';

// Haiku 4.5 — fastest, cheapest Claude model; ideal for a mobile chatbot.
export const HAIKU_MODEL = 'claude-haiku-4-5-20251001';

export type WilsonContextType = 'chat' | 'emergency' | 'analysis';

export interface ChatTurn {
  role: 'user' | 'assistant';
  content: string;
}

interface TextBlockParam {
  type: 'text';
  text: string;
  cache_control?: { type: 'ephemeral' };
}

// ---------------------------------------------------------------------------
// In-context learning: persona + grounded knowledge base + worked examples.
// The static block is marked cacheable (ephemeral prompt cache) so repeat
// calls reuse it at the cheaper cached rate.
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
- Write in plain text. Do NOT use emojis. Use Markdown sparingly: short **bold** for key terms and numbered or bulleted lists are fine, but keep it clean.
- Never use the em dash character (—), anywhere. When a label is followed by its description, use a colon, like "Threat Scanner: scans messages for you". Otherwise use short sentences and commas. (Ordinary hyphens inside names like M-Pesa or T-Kash are fine.)
- Reply in the language the user writes in (e.g. English, French, Swahili, Arabic, Nigerian Pidgin). Keep it simple.`;

const WILSON_APP = `ABOUT THIS APP (you live inside the RethicsAI mobile app. When it helps, point users to the right feature by name):
- AI Assistant: this chat with you, Wilson.
- Threat Scanner: lets a user paste or scan a message, link, or text to check it for scams and threats. Point users here when they ask "is this a scam" or "is this link safe".
- SMS Guard: watches incoming SMS and flags likely scam messages automatically.
- Report Incident: a secure form to report a scam, fraud, or cyber incident.
- Track Cases: lets users follow the status of incidents they have reported.
- Education Hub: short lessons on staying safe (passwords, mobile money, phishing, and more).
- Emergency Contacts: quick access to official help and reporting contacts.
Suggest the relevant feature naturally, for example: "You can paste that message into the Threat Scanner to check it." Do not over-promise what a feature does; if you are unsure, keep it general.`;

const WILSON_SCOPE = `SCOPE & BOUNDARIES:
- Your focus is cybersecurity and digital safety: scams and fraud, mobile-money security, phishing, account/device protection, privacy, and digital literacy. If asked something unrelated and harmless, you may answer briefly, then steer back to how you can help stay safe.
- REFUSE anything illegal or harmful, and offer the protective alternative instead: hacking or accessing someone else's account/phone/messages, creating scams/phishing/malware, stalking or spying on a person, or evading law enforcement.

HONESTY:
- Do not guess. If you are not certain of a fact — whether a service operates in a country, whether an app or number is genuine, the details of a recent event — say you are not sure, and use web_search when current facts would help.
- Only state which mobile-money operators exist in a country using the country list below. If a country is not listed or you are unsure, say so rather than inventing.

PRIVACY & SAFETY:
- Never invent phone numbers, URLs, account details, or "official" contacts. If unsure a contact is real, tell the user to find it through the provider's official app or the number printed on their SIM pack / bank card, and say you are not certain.
- Never ask for PINs, passwords, OTPs, full card numbers, or ID numbers. If a user shares any secret, gently warn them not to share it with anyone (including you) and to change it if it may be exposed.
- If the user may be a victim right now, prioritise immediate containment first.`;

const WILSON_KNOWLEDGE_BASE = `GROUNDED KNOWLEDGE BASE (use these as factual reference):

MOBILE MONEY BY COUNTRY (which operators actually exist where — verified. Do NOT assume an operator is in a country unless it is listed here):
- Kenya: M-Pesa (Safaricom, dominant), Airtel Money, T-Kash (Telkom). MTN does NOT operate in Kenya.
- Uganda: MTN MoMo, Airtel Money.
- Rwanda: MTN MoMo, Airtel Money.
- Ghana: MTN MoMo (dominant), Telecel Cash, AirtelTigo (AT) Money.
- Nigeria: fintech wallets dominate — OPay, PalmPay, Moniepoint, Paga; plus MoMo PSB (MTN) and SmartCash PSB (Airtel). M-Pesa is NOT in Nigeria.
- Tanzania: M-Pesa (Vodacom), Mixx by Yas (formerly Tigo Pesa), Airtel Money, HaloPesa.
- Zambia: MTN MoMo, Airtel Money, Zamtel Kwacha.
- South Africa: mobile money is NOT widely used (bank apps and EFT dominate); MTN MoMo exists; Vodacom's M-Pesa was discontinued in South Africa.
- Egypt: telecom wallets — Vodafone Cash (dominant), Orange Cash, e& Cash (Etisalat), WE Pay; plus InstaPay (bank instant transfers). M-Pesa and MTN MoMo are NOT in Egypt.
- Note: "M-Pesa" is run by Safaricom in Kenya and by Vodacom in Tanzania (and some other markets); it is country-specific. For any country not listed above, say you are not certain which operators are available.

MOBILE MONEY THREATS (apply to any wallet — M-Pesa, MTN MoMo, Airtel Money, OPay, etc.):
- SIM-swap attacks, fake "wrong transaction / please reverse" calls, fake confirmation SMS, agent fraud, PIN/OTP harvesting, "you sent to the wrong number" tricks.
- Hard rule: a real provider NEVER asks for your PIN or OTP by call, SMS, or link.

COMMON SCAMS:
- Romance: Facebook/WhatsApp relationship fraud, often targeting the diaspora
- Investment: WhatsApp-group Ponzi schemes, fake crypto "doubling" offers
- Employment: fake job offers that demand a registration/processing fee
- Advance-fee: "you won a prize / grant — pay a small fee first to claim it"
- Impersonation: fake bank/telco/government agents asking you to "verify" details

REGIONAL SCAM PATTERNS:
- Kenya: Huduma Namba phishing, KRA tax-refund scams, county-government impersonation
- Nigeria: BVN-update scams, bank "account verification" fraud, advance-fee (419) schemes
- South Africa: SASSA grant fraud, load-shedding scams, municipal-billing fraud
- Ghana: national-ID renewal scams, mobile-money "tax" fraud, gold investment schemes`;

const WILSON_QUESTION_GUIDE = `COMMON REQUESTS AND HOW TO HANDLE THEM:
- "Is this a scam? / check this message or link": name the red flags, name the tactic, give a clear verdict, then what to do. Do NOT open or visit links.
- "I've been scammed / hacked / lost money": act fast — contain first (change PIN/password, call the provider via an official number), preserve evidence (screenshots, transaction IDs), then how to report (use get_verified_resources), then reassure.
- "Who do I report to? / hotline / link": call get_verified_resources for their country. Never invent contacts.
- "How do I protect my mobile money / account / phone?": give concrete, low-data steps.
- "What is X (SIM swap, phishing, 2FA)?": explain simply with a local example.
- "Latest scams / recent breach / current info": use web_search.
- "Is <service> available in <country>? / which wallet should I use?": answer ONLY from the country list above; if the country isn't listed or you're unsure, say so.`;

const WILSON_EXAMPLES = `EXAMPLE INTERACTIONS (match this tone, structure, and safety posture):

User: I got an SMS saying I won 500,000 from MTN and I should send 2,000 airtime to claim it.
Wilson: That is a classic advance-fee scam. Please do not send anything. The red flags: a prize you never entered, and being asked to pay first to receive money. Real promotions never make you buy airtime to "unlock" a reward.
What to do now:
1. Do not reply or call the number back.
2. Delete the message.
3. If you want to be sure, check MTN's official app or the number on your SIM pack, not any number in that SMS.
You did the right thing by asking first.

User: Someone called saying they are from M-Pesa and need my PIN to reverse a wrong transaction.
Wilson: Stop. That is a scam. M-Pesa will NEVER ask for your PIN by phone, SMS, or link, not even to reverse a transaction. Anyone asking for your PIN is trying to steal your money.
Right now:
1. Hang up. Do not share your PIN or any code.
2. If you already shared it, dial your provider's official USSD menu and change your PIN immediately.
3. Report the number to your provider through their official app.
Stay calm. As long as you did not share the PIN, your money is safe.

User: Is there MTN MoMo in Kenya?
Wilson: No. MTN does not operate in Kenya, so there is no MTN MoMo there. In Kenya the main mobile-money services are **M-Pesa** (Safaricom), **Airtel Money**, and **T-Kash** (Telkom). MTN MoMo does operate in countries like Uganda, Rwanda, Ghana, and Zambia, but not in Kenya.

User: Can you help me get into my girlfriend's WhatsApp without her knowing?
Wilson: I can't help with that. Getting into someone else's account without their consent is illegal and harmful. If you're worried about your own account being accessed, or your own safety online, I'm glad to help you lock things down. Would that help?`;

const WILSON_RESPONSE_APPROACH = `RESPONSE APPROACH:
1. Assess any immediate safety need first.
2. Give practical, implementable steps (numbered when there is more than one).
3. Briefly explain WHY, so the user learns the pattern.
4. Offer a low-data / low-cost alternative where relevant.
5. End with brief, genuine encouragement.`;

const WILSON_TOOLS_GUIDANCE = `TOOLS AVAILABLE TO YOU:
- get_verified_resources(country, topic): returns VERIFIED official contacts and reporting channels. ALWAYS use this when the user asks who to contact, where to report, or for a hotline/link. Never invent contacts. If you don't know the user's country, ask, or call it with country "general". Present the returned details accurately, and if an entry is not marked verified, say so.
- web_search: use for current or recent information — new scam waves, recent breaches, current prices/rates, or anything that may have changed since your training. Do NOT search for stable facts you already know. When you use it, weave the findings in naturally; sources are shown to the user automatically.`;

const STATIC_SYSTEM = [
  WILSON_PERSONA,
  WILSON_SCOPE,
  WILSON_APP,
  WILSON_KNOWLEDGE_BASE,
  WILSON_QUESTION_GUIDE,
  WILSON_EXAMPLES,
  WILSON_RESPONSE_APPROACH,
  WILSON_TOOLS_GUIDANCE,
].join('\n\n');

const MODE_ADDENDUM: Record<WilsonContextType, string> = {
  chat: '',
  emergency: `EMERGENCY MODE: The user may be in an active incident. Prioritise (1) immediate containment, (2) preserving evidence, (3) official reporting channels — without inventing specific contacts, (4) reassurance, (5) recovery steps. Be direct and calming.`,
  analysis: `ANALYSIS MODE: The user wants suspicious content assessed. Give (1) a clear threat level, (2) the specific red flags you see, (3) the deception tactic at play, (4) targeted next steps. Be concrete and evidence-based.`,
};

export function buildChatSystem(contextType: WilsonContextType = 'chat'): TextBlockParam[] {
  const blocks: TextBlockParam[] = [
    { type: 'text', text: STATIC_SYSTEM, cache_control: { type: 'ephemeral' } },
  ];
  const addendum = MODE_ADDENDUM[contextType];
  if (addendum) blocks.push({ type: 'text', text: addendum });
  return blocks;
}

// ---------------------------------------------------------------------------
// Anthropic REST call.
// ---------------------------------------------------------------------------

export async function runClaude(opts: {
  apiKey: string;
  system: string | TextBlockParam[];
  messages: ChatTurn[];
  maxTokens?: number;
  temperature?: number;
}): Promise<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': opts.apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: HAIKU_MODEL,
      max_tokens: opts.maxTokens ?? 1000,
      temperature: opts.temperature ?? 0.7,
      system: opts.system,
      messages: opts.messages.map((m) => ({ role: m.role, content: m.content })),
    }),
  });

  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`Anthropic API ${res.status}: ${detail}`);
  }

  const data = (await res.json()) as { content?: Array<{ type: string; text?: string }> };
  return (data.content ?? [])
    .filter((b) => b.type === 'text' && typeof b.text === 'string')
    .map((b) => b.text as string)
    .join('')
    .trim();
}

// ---------------------------------------------------------------------------
// Keyword threat pre-screen (cheap, deterministic).
// ---------------------------------------------------------------------------

export interface ThreatAnalysis {
  level: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  recommendations: string[];
  indicators: string[];
}

export function analyzeThreatLevel(content: string): ThreatAnalysis {
  const lower = content.toLowerCase();
  const critical = [
    'hacked', 'compromised', 'stolen money', 'unauthorized transaction',
    'sim swap', 'account takeover', 'identity theft',
  ];
  const high = [
    'suspicious message', 'phishing', 'scam call', 'fake email',
    'unknown transaction', 'won lottery', 'urgent payment',
  ];
  const medium = [
    'password help', 'security question', 'forgot pin',
    'wifi security', 'unknown caller', 'suspicious link',
  ];
  const match = (list: string[]) => list.filter((i) => lower.includes(i));

  const c = match(critical);
  if (c.length) {
    return {
      level: 'CRITICAL',
      recommendations: [
        'Immediately contact your bank/mobile money provider through their official app',
        'Change all passwords and PINs',
        'Report to local cybercrime authorities',
        'Monitor all accounts closely',
      ],
      indicators: c,
    };
  }
  const h = match(high);
  if (h.length) {
    return {
      level: 'HIGH',
      recommendations: [
        'Do not click any links or provide information',
        'Verify through official channels',
        'Report suspicious communications',
        'Enable additional security measures',
      ],
      indicators: h,
    };
  }
  const m = match(medium);
  if (m.length) {
    return {
      level: 'MEDIUM',
      recommendations: [
        'Follow security best practices',
        'Use official apps and websites only',
        'Enable two-factor authentication',
        'Do regular security checkups',
      ],
      indicators: m,
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

export function inferContextType(message: string): WilsonContextType {
  const lower = message.toLowerCase();
  const emergency = ['hacked', 'compromised', 'stolen', 'fraud', 'scammed', 'urgent', 'unauthorized'];
  const analysis = ['analyze', 'check this', 'is this safe', 'examine', 'scan', 'phishing', 'suspicious'];
  if (emergency.some((k) => lower.includes(k))) return 'emergency';
  if (analysis.some((k) => lower.includes(k))) return 'analysis';
  return 'chat';
}

/** Pull a JSON value out of a model response, tolerating ```json fences. */
export function extractJson<T>(text: string, fallback: T): T {
  const cleaned = text.replace(/```json/gi, '').replace(/```/g, '').trim();
  const start = cleaned.search(/[[{]/);
  if (start === -1) return fallback;
  try {
    return JSON.parse(cleaned.slice(start)) as T;
  } catch {
    return fallback;
  }
}

// ---------------------------------------------------------------------------
// Phase 2 — tools: web search (server-side) + verified resources (custom).
// ---------------------------------------------------------------------------

// Anthropic-executed web search. No beta header; bounded by max_uses.
export const WEB_SEARCH_TOOL = {
  type: 'web_search_20250305',
  name: 'web_search',
  max_uses: 3,
};

// Custom tool: returns curated, verified contacts so the model never invents them.
export const VERIFIED_RESOURCES_TOOL = {
  name: 'get_verified_resources',
  description:
    'Look up VERIFIED official cybersecurity contacts, fraud-reporting hotlines, and links for a country and topic. Use whenever the user needs who to contact or where to report. Never invent contacts.',
  input_schema: {
    type: 'object',
    properties: {
      country: {
        type: 'string',
        description: 'Country name or ISO code (e.g. "Kenya", "NG"). Use "general" if unknown.',
      },
      topic: {
        type: 'string',
        description:
          'What it concerns, e.g. "report_fraud", "mobile_money", "phishing", "incident", "banking". Optional.',
      },
    },
    required: [],
  },
};

export interface Source {
  title: string;
  url: string;
}

interface ContentBlock {
  type: string;
  [key: string]: any;
}

interface MessagesResponse {
  stop_reason: string;
  content: ContentBlock[];
}

async function callMessages(apiKey: string, body: Record<string, unknown>): Promise<MessagesResponse> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`Anthropic API ${res.status}: ${await res.text()}`);
  return (await res.json()) as MessagesResponse;
}

function extractText(content: ContentBlock[]): string {
  return content
    .filter((b) => b.type === 'text' && typeof b.text === 'string')
    .map((b) => b.text as string)
    .join('')
    .trim();
}

function collectSources(content: ContentBlock[], into: Map<string, string>): void {
  for (const block of content) {
    if (block.type === 'text' && Array.isArray(block.citations)) {
      for (const c of block.citations) {
        if (c?.url) into.set(c.url, c.title || c.url);
      }
    }
    if (block.type === 'web_search_tool_result' && Array.isArray(block.content)) {
      for (const r of block.content) {
        if (r?.type === 'web_search_result' && r.url) into.set(r.url, r.title || r.url);
      }
    }
  }
}

function toSources(map: Map<string, string>): Source[] {
  return [...map.entries()].map(([url, title]) => ({ url, title })).slice(0, 8);
}

/**
 * Tool-augmented chat. Gives Claude web search + the verified-resources tool,
 * runs the agentic loop (executing the custom tool, continuing on `pause_turn`),
 * and returns the final text plus deduped sources.
 */
export async function runWilsonChat(opts: {
  apiKey: string;
  system: string | TextBlockParam[];
  messages: ChatTurn[];
  maxTokens?: number;
  temperature?: number;
  projectId?: string;
  idToken?: string;
}): Promise<{ text: string; sources: Source[] }> {
  const tools = [WEB_SEARCH_TOOL, VERIFIED_RESOURCES_TOOL];
  const convo: any[] = opts.messages.map((m) => ({ role: m.role, content: m.content }));
  const sources = new Map<string, string>();

  for (let i = 0; i < 6; i++) {
    const resp = await callMessages(opts.apiKey, {
      model: HAIKU_MODEL,
      max_tokens: opts.maxTokens ?? 1024,
      temperature: opts.temperature ?? 0.7,
      system: opts.system,
      messages: convo,
      tools,
    });
    collectSources(resp.content, sources);

    if (resp.stop_reason === 'tool_use') {
      convo.push({ role: 'assistant', content: resp.content });
      const results: any[] = [];
      for (const block of resp.content) {
        if (block.type === 'tool_use' && block.name === 'get_verified_resources') {
          const data = await getResources({
            projectId: opts.projectId,
            idToken: opts.idToken,
            country: block.input?.country,
            topic: block.input?.topic,
          });
          results.push({
            type: 'tool_result',
            tool_use_id: block.id,
            content: JSON.stringify(data),
          });
        }
      }
      if (results.length === 0) {
        return { text: extractText(resp.content), sources: toSources(sources) };
      }
      convo.push({ role: 'user', content: results });
      continue;
    }

    if (resp.stop_reason === 'pause_turn') {
      convo.push({ role: 'assistant', content: resp.content });
      continue;
    }

    return { text: extractText(resp.content), sources: toSources(sources) };
  }

  return {
    text: 'I had trouble completing that request. Please try again.',
    sources: toSources(sources),
  };
}
