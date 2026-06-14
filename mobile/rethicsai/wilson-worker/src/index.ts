/**
 * Wilson AI proxy — Cloudflare Worker.
 *
 * Free, no-credit-card backend for the RethicsAI mobile chatbot. Verifies the
 * caller's Firebase ID token, then calls Claude Haiku. Replaces the Firebase
 * Cloud Functions path (which requires the Blaze plan).
 *
 * Routes (all POST, all require `Authorization: Bearer <firebaseIdToken>`):
 *   /chat        -> conversational assistant
 *   /analyze     -> assess suspicious content (JSON)
 *   /insights    -> daily cybersecurity tips (JSON)
 *   /threat-intel-> regional threat intelligence (JSON)
 *   /training    -> generate training content
 */
import { getBearerToken, verifyFirebaseToken } from './auth';
import {
  analyzeThreatLevel,
  buildChatSystem,
  ChatTurn,
  extractJson,
  inferContextType,
  runClaude,
  runWilsonChat,
  Source,
  WilsonContextType,
} from './wilson';

export interface Env {
  ANTHROPIC_API_KEY: string;
  FIREBASE_PROJECT_ID: string;
}

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Max-Age': '86400',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...CORS_HEADERS },
  });
}

function randomId(): string {
  return crypto.randomUUID().replace(/-/g, '').slice(0, 20);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }
    if (request.method !== 'POST') {
      return json({ error: 'Method Not Allowed' }, 405);
    }

    // --- Authenticate -------------------------------------------------------
    const token = getBearerToken(request);
    if (!token) return json({ error: 'Unauthorized' }, 401);
    try {
      await verifyFirebaseToken(token, env.FIREBASE_PROJECT_ID);
    } catch (e) {
      return json({ error: 'Unauthorized', detail: (e as Error).message }, 401);
    }
    // `token` is verified; reused to read Firestore (rules enforced) for the
    // verified-resources tool.

    if (!env.ANTHROPIC_API_KEY) {
      return json({ error: 'Server misconfigured: missing ANTHROPIC_API_KEY' }, 500);
    }

    const url = new URL(request.url);
    let body: any;
    try {
      body = await request.json();
    } catch {
      body = {};
    }

    try {
      switch (url.pathname) {
        case '/chat':
          return await handleChat(body, env, token);
        case '/analyze':
          return await handleAnalyze(body, env);
        case '/insights':
          return await handleInsights(env);
        case '/threat-intel':
          return await handleThreatIntel(body, env);
        case '/training':
          return await handleTraining(body, env);
        default:
          return json({ error: 'Not found' }, 404);
      }
    } catch (e) {
      console.error('Wilson worker error:', e);
      return json({ error: 'Internal error', detail: (e as Error).message }, 500);
    }
  },
};

// --- Handlers -------------------------------------------------------------

async function handleChat(body: any, env: Env, idToken: string): Promise<Response> {
  const incoming: ChatTurn[] = body?.messages;
  if (!Array.isArray(incoming) || incoming.length === 0) {
    return json({ error: 'Messages array is required' }, 400);
  }

  // The Claude Messages API requires the conversation to start with a user
  // message. Drop empty turns and any leading assistant messages (e.g. a
  // client-side welcome greeting) so a stray greeting can't 400 the request.
  const cleaned = incoming.filter(
    (m) => m && typeof m.content === 'string' && m.content.trim().length > 0,
  );
  const firstUser = cleaned.findIndex((m) => m.role === 'user');
  const messages = firstUser === -1 ? [] : cleaned.slice(firstUser);
  if (messages.length === 0) {
    return json({ error: 'A user message is required' }, 400);
  }

  const latest = messages[messages.length - 1]?.content ?? '';
  const contextType: WilsonContextType = body?.contextType || inferContextType(latest);
  const threat = analyzeThreatLevel(latest);
  const system = buildChatSystem(contextType);

  let text: string;
  let sources: Source[] = [];
  try {
    // Tool-augmented path: web search + verified resources.
    const result = await runWilsonChat({
      apiKey: env.ANTHROPIC_API_KEY,
      system,
      messages,
      maxTokens: 1024,
      temperature: 0.7,
      projectId: env.FIREBASE_PROJECT_ID,
      idToken,
    });
    text = result.text;
    sources = result.sources;
  } catch (e) {
    // Fall back to a plain call if tools are unavailable (e.g. web search not
    // enabled for the org, or a transient tool error).
    console.warn('Tool-augmented chat failed, falling back to plain chat:', e);
    text = await runClaude({
      apiKey: env.ANTHROPIC_API_KEY,
      system,
      messages,
      maxTokens: 1000,
      temperature: 0.7,
    });
  }

  return json({
    response: withSources(text || 'I could not generate a response at this time. Please try again.', sources),
    messageId: randomId(),
    timestamp: Date.now(),
    sessionId: body?.sessionId || randomId(),
    threatLevel: threat.level,
    recommendations: threat.recommendations,
  });
}

/** Append a short Sources section (Markdown links) when web search contributed. */
function withSources(text: string, sources: Source[]): string {
  if (!sources.length) return text;
  const lines = sources.map((s) => `- [${s.title}](${s.url})`).join('\n');
  return `${text}\n\n**Sources:**\n${lines}`;
}

async function handleAnalyze(body: any, env: Env): Promise<Response> {
  const content: string = body?.content;
  const contentType: string = body?.contentType || 'content';
  if (!content) return json({ error: 'Content is required' }, 400);

  const prescreen = analyzeThreatLevel(content);
  const prompt = `Analyze the following ${contentType} for cybersecurity threats, scams, or malicious intent, with an African context (mobile-money scams, social engineering, phishing, fake job offers, romance scams, investment fraud).

Content to analyze:
"""
${content}
"""

Respond with ONLY a JSON object with these keys:
- "threatLevel": one of "LOW", "MEDIUM", "HIGH", "CRITICAL"
- "threatTypes": array of strings
- "redFlags": array of strings
- "recommendations": array of short actionable strings
- "analysis": a short plain-language summary string`;

  const raw = await runClaude({
    apiKey: env.ANTHROPIC_API_KEY,
    system: 'You are a cybersecurity analyst specializing in African digital threats. Output only valid JSON, no prose, no code fences.',
    messages: [{ role: 'user', content: prompt }],
    maxTokens: 800,
    temperature: 0.2,
  });

  const parsed = extractJson<Record<string, unknown>>(raw, {
    threatLevel: prescreen.level,
    threatTypes: [],
    redFlags: prescreen.indicators,
    recommendations: prescreen.recommendations,
    analysis: raw,
  });

  return json({ ...parsed, analysisId: randomId(), timestamp: Date.now() });
}

async function handleInsights(env: Env): Promise<Response> {
  const prompt = `Generate 3-5 current cybersecurity tips for African users in ${new Date().getFullYear()}. Focus on mobile-first practices, the current African threat landscape, low-resource environments, mobile-money security, social-media safety, and SME email security.

Respond with ONLY a JSON array. Each item must have: "title", "description", "category", "priority" (low|medium|high), "actionable_tip".`;

  const raw = await runClaude({
    apiKey: env.ANTHROPIC_API_KEY,
    system: 'You are a cybersecurity expert giving practical, culturally relevant daily insights for African technology users. Output only a valid JSON array, no prose, no code fences.',
    messages: [{ role: 'user', content: prompt }],
    maxTokens: 1200,
    temperature: 0.8,
  });

  const insights = extractJson<unknown[]>(raw, [
    {
      title: 'Daily Security Reminder',
      description: 'Stay vigilant online and keep your devices updated.',
      category: 'general',
      priority: 'medium',
      actionable_tip: 'Check for app updates today.',
    },
  ]);

  return json({
    insights,
    generated_at: Date.now(),
    expires_at: Date.now() + 24 * 60 * 60 * 1000,
  });
}

async function handleThreatIntel(body: any, env: Env): Promise<Response> {
  const region: string = body?.region || 'africa';
  const prompt = `Generate current cybersecurity threat intelligence for ${region} in ${new Date().getFullYear()}. Include the top emerging threats, mobile-money security alerts, social-engineering tactics targeting the African diaspora, country-specific scam patterns, and recommended protective measures.

Respond with ONLY a JSON object: { "threats": [ { "category": string, "severity": "LOW"|"MEDIUM"|"HIGH"|"CRITICAL", "description": string, "recommendation": string } ] }`;

  const raw = await runClaude({
    apiKey: env.ANTHROPIC_API_KEY,
    system: 'You are a cybersecurity threat-intelligence analyst specializing in African digital threats. Output only valid JSON, no prose, no code fences.',
    messages: [{ role: 'user', content: prompt }],
    maxTokens: 1000,
    temperature: 0.5,
  });

  const parsed = extractJson<{ threats: unknown[] }>(raw, {
    threats: [
      {
        category: 'Mobile Money Fraud',
        severity: 'HIGH',
        description: 'Increased SIM-swap attacks targeting mobile-money accounts',
        recommendation: 'Enable additional verification for all mobile-money transactions',
      },
    ],
  });

  return json({
    ...parsed,
    region,
    timestamp: Date.now(),
    expires_at: Date.now() + 6 * 60 * 60 * 1000,
  });
}

async function handleTraining(body: any, env: Env): Promise<Response> {
  const topic: string = body?.topic;
  const level: string = body?.level;
  const language: string = body?.language || 'english';
  if (!topic || !level) return json({ error: 'topic and level are required' }, 400);

  const prompt = `Create comprehensive cybersecurity training content for topic "${topic}" at "${level}" level in ${language}. Include learning objectives, interactive scenarios with African context, practical exercises using local examples (M-Pesa, local banks), assessment questions, real-world African case studies, community-sharing activities, and follow-up resources. Make it engaging, practical, and culturally relevant.`;

  const content = await runClaude({
    apiKey: env.ANTHROPIC_API_KEY,
    system: 'You are Wilson, a cybersecurity education specialist creating culturally relevant training for African users.',
    messages: [{ role: 'user', content: prompt }],
    maxTokens: 2000,
    temperature: 0.7,
  });

  return json({
    topic,
    level,
    language,
    content,
    generated_at: Date.now(),
    expires_at: Date.now() + 7 * 24 * 60 * 60 * 1000,
    version: '1.0',
  });
}
