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

/**
 * Enhanced Wilson AI chat path. Historically this used Vertex AI Gemini; it now
 * runs on Claude Haiku via the shared `wilsonClaude` layer. The export names are
 * preserved (`wilsonAIVertex`, `getAfricanThreatIntelligence`,
 * `generateSecurityTraining`) so the mobile client needs no changes.
 */

const withSecret = functions.runWith({ secrets: [ANTHROPIC_SECRET] });

function requireAuth(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  return context.auth.uid;
}

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

interface WilsonAIData {
  messages?: ChatTurn[];
  sessionId?: string;
  contextType?: WilsonContextType;
}

// Wilson AI enhanced chat — Claude Haiku with African-context in-context learning.
export const wilsonAIVertex = withSecret.https.onCall(async (data: WilsonAIData, context) => {
  const uid = requireAuth(context);
  const { messages, sessionId, contextType = 'chat' } = data || {};

  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Messages array is required');
  }

  const latest = messages[messages.length - 1];
  const threatAnalysis = analyzeThreatLevel(latest.content);

  let responseText: string;
  try {
    responseText = await runClaude({
      system: buildChatSystem(contextType),
      messages,
      maxTokens: 1000,
      temperature: 0.7,
    });
  } catch (error) {
    console.error('Wilson AI Claude Error:', error);
    return {
      response: `I'm temporarily having connection issues, but I'm still here to help! 🛡️

Quick reminders while I reconnect:
🔐 Use unique passwords for banking, social media, and work
📱 Never share your M-Pesa/MTN PIN with anyone, even family
📧 Banks never ask for PINs via SMS or call
📶 Avoid banking on public WiFi
🆔 Verify "winner" messages through official channels

What security topic can I help you with?`,
      messageId: admin.firestore().collection('temp').doc().id,
      timestamp: Date.now(),
      sessionId: sessionId || 'fallback-session',
      threatLevel: threatAnalysis.level,
      recommendations: threatAnalysis.recommendations,
    };
  }

  const resolvedSession = sessionId || admin.firestore().collection('temp').doc().id;
  const responseData = {
    response: responseText,
    messageId: admin.firestore().collection('temp').doc().id,
    timestamp: Date.now(),
    sessionId: resolvedSession,
    threatLevel: threatAnalysis.level,
    recommendations: threatAnalysis.recommendations,
  };

  try {
    const session = admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('wilsonSessions')
      .doc(resolvedSession);

    await session.collection('messages').add({
      role: 'user',
      content: latest.content,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      threatAnalysis,
      contextType,
    });
    await session.collection('messages').add({
      role: 'assistant',
      content: responseText,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      model: 'claude-haiku-4-5',
      contextType,
    });
    await session.set(
      {
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        messageCount: admin.firestore.FieldValue.increment(2),
        userId: uid,
        model: 'claude-haiku-4-5',
      },
      { merge: true },
    );
  } catch (firestoreError) {
    console.warn('Failed to store enhanced chat history:', firestoreError);
  }

  return responseData;
});

interface ThreatIntelData {
  region?: string;
}

// Real-time African threat intelligence.
export const getAfricanThreatIntelligence = withSecret.https.onCall(async (data: ThreatIntelData, context) => {
  requireAuth(context);
  const region = data?.region || 'africa';

  const prompt = `Generate current cybersecurity threat intelligence for ${region} in ${new Date().getFullYear()}. Include the top emerging threats, mobile-money security alerts, social-engineering tactics targeting the African diaspora, country-specific scam patterns, and recommended protective measures.

Respond with ONLY a JSON object: { "threats": [ { "category": string, "severity": "LOW"|"MEDIUM"|"HIGH"|"CRITICAL", "description": string, "recommendation": string } ] }`;

  const raw = await runClaude({
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

  return {
    ...parsed,
    region,
    timestamp: Date.now(),
    expires_at: Date.now() + 6 * 60 * 60 * 1000,
  };
});

interface TrainingData {
  topic?: string;
  level?: string;
  language?: string;
}

// Cybersecurity training content generator.
export const generateSecurityTraining = withSecret.https.onCall(async (data: TrainingData, context) => {
  requireAuth(context);
  const { topic, level, language = 'english' } = data || {};

  if (!topic || !level) {
    throw new functions.https.HttpsError('invalid-argument', 'topic and level are required');
  }

  const prompt = `Create comprehensive cybersecurity training content for topic "${topic}" at "${level}" level in ${language}. Include learning objectives, interactive scenarios with African context, practical exercises using local examples (M-Pesa, local banks), assessment questions, real-world African case studies, community-sharing activities, and follow-up resources. Make it engaging, practical, and culturally relevant.`;

  const content = await runClaude({
    system: 'You are Wilson, a cybersecurity education specialist creating culturally relevant training for African users.',
    messages: [{ role: 'user', content: prompt }],
    maxTokens: 2000,
    temperature: 0.7,
  });

  return {
    topic,
    level,
    language,
    content,
    generated_at: Date.now(),
    expires_at: Date.now() + 7 * 24 * 60 * 60 * 1000,
    version: '1.0',
  };
});
