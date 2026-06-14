import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  ANTHROPIC_SECRET,
  analyzeThreatLevel,
  buildChatSystem,
  ChatTurn,
  runClaude,
  WilsonContextType,
} from './wilsonClaude';

// Claude-powered Wilson AI functions that live in their own module.
export {
  wilsonAIVertex,
  getAfricanThreatIntelligence,
  generateSecurityTraining,
} from './wilsonAIVertexModel';

admin.initializeApp();

const withSecret = functions.runWith({ secrets: [ANTHROPIC_SECRET] });

function requireAuth(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  return context.auth.uid;
}

/** Pull a JSON value out of a model response, tolerating ```json fences. */
function extractJson<T>(text: string, fallback: T): T {
  const cleaned = text.replace(/```json/gi, '').replace(/```/g, '').trim();
  const start = cleaned.search(/[[{]/);
  if (start === -1) return fallback;
  try {
    return JSON.parse(cleaned.slice(start)) as T;
  } catch {
    return fallback;
  }
}

interface WilsonChatData {
  messages?: ChatTurn[];
  sessionId?: string;
}

// Wilson AI chat — Claude Haiku with African-context in-context learning.
export const wilsonChat = withSecret.https.onCall(async (data: WilsonChatData, context) => {
  const uid = requireAuth(context);
  const { messages, sessionId } = data || {};

  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Messages array is required');
  }

  const lastMessage = messages[messages.length - 1]?.content ?? '';
  const contextType = inferContextType(lastMessage);

  const aiResponse = await runClaude({
    system: buildChatSystem(contextType),
    messages,
    maxTokens: 1000,
    temperature: 0.7,
  });

  const resolvedSession = sessionId || admin.firestore().collection('temp').doc().id;
  const responseData = {
    response: aiResponse || 'I could not generate a response at this time. Please try again.',
    messageId: admin.firestore().collection('temp').doc().id,
    timestamp: Date.now(),
    sessionId: resolvedSession,
  };

  try {
    const session = admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('chatSessions')
      .doc(resolvedSession)
      .collection('messages');

    await session.add({
      ...messages[messages.length - 1],
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    await session.add({
      role: 'assistant',
      content: responseData.response,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (firestoreError) {
    console.warn('Failed to store chat history:', firestoreError);
  }

  return responseData;
});

function inferContextType(message: string): WilsonContextType {
  const lower = message.toLowerCase();
  const emergency = ['hacked', 'compromised', 'stolen', 'fraud', 'scammed', 'urgent', 'unauthorized'];
  const analysis = ['analyze', 'check this', 'is this safe', 'examine', 'scan', 'phishing', 'suspicious'];
  if (emergency.some((k) => lower.includes(k))) return 'emergency';
  if (analysis.some((k) => lower.includes(k))) return 'analysis';
  return 'chat';
}

interface AnalyzeData {
  content?: string;
  contentType?: string;
}

// Analyze suspicious content for cybersecurity threats.
export const analyzeSuspiciousContent = withSecret.https.onCall(async (data: AnalyzeData, context) => {
  requireAuth(context);
  const { content, contentType } = data || {};

  if (!content) {
    throw new functions.https.HttpsError('invalid-argument', 'Content is required');
  }

  const prescreen = analyzeThreatLevel(content);

  const prompt = `Analyze the following ${contentType || 'content'} for cybersecurity threats, scams, or malicious intent, with an African context (mobile-money scams, social engineering, phishing, fake job offers, romance scams, investment fraud).

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

  return {
    ...parsed,
    analysisId: admin.firestore().collection('temp').doc().id,
    timestamp: Date.now(),
  };
});

// Daily cybersecurity insights tailored to African users.
export const getCyberInsights = withSecret.https.onCall(async (_data, context) => {
  requireAuth(context);

  const prompt = `Generate 3-5 current cybersecurity tips for African users in ${new Date().getFullYear()}. Focus on mobile-first practices, the current African threat landscape, low-resource environments, mobile-money security, social-media safety, and SME email security.

Respond with ONLY a JSON array. Each item must have: "title", "description", "category", "priority" (low|medium|high), "actionable_tip".`;

  const raw = await runClaude({
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

  return {
    insights,
    generated_at: Date.now(),
    expires_at: Date.now() + 24 * 60 * 60 * 1000,
  };
});
