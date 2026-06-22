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

// Map a stored notification `type` (NotificationType.name from the app) to the
// Android channel the client registered in NotificationService.
function channelForType(type?: string): string {
  switch (type) {
    case 'caseUpdate':
      return 'case_updates';
    case 'educationAchievement':
      return 'education';
    case 'securityAlert':
      return 'security_alerts';
    default:
      return 'general';
  }
}

// Push delivery: when a notification document is created, look up the
// recipient's FCM token and send a real push so backgrounded/closed devices
// receive it (the in-app inbox is written by the client; this adds delivery).
// Ownership field is snake_case `user_id` from the app, but accept `userId` too.
export const onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap) => {
    const notif = snap.data() || {};
    const recipientUid: string | undefined = notif.user_id || notif.userId;

    if (!recipientUid) {
      functions.logger.warn('notification missing recipient uid', {
        id: snap.id,
      });
      return;
    }

    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(recipientUid)
      .get();
    const token: string | undefined = userSnap.get('fcmToken');

    if (!token) {
      functions.logger.info('no fcmToken for recipient; skipping push', {
        uid: recipientUid,
      });
      return;
    }

    const channelId = channelForType(notif.type);

    // Firestore data must be string->string for FCM data payloads.
    const dataPayload: Record<string, string> = {
      type: String(notif.type ?? 'general'),
      notificationId: snap.id,
    };
    const extra = notif.data;
    if (extra && typeof extra === 'object') {
      for (const [k, v] of Object.entries(extra)) {
        if (v != null && typeof v !== 'object') dataPayload[k] = String(v);
      }
    }

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: notif.title ?? 'RethicsAI',
          body: notif.body ?? '',
        },
        data: dataPayload,
        android: {
          priority: 'high',
          notification: { channelId },
        },
        apns: {
          payload: { aps: { sound: 'default' } },
        },
      });
      functions.logger.info('push sent', { uid: recipientUid, channelId });
    } catch (err) {
      const code = (err as { code?: string })?.code;
      // Token went stale (app uninstalled / token rotated) — clean it up.
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        await admin
          .firestore()
          .collection('users')
          .doc(recipientUid)
          .update({ fcmToken: admin.firestore.FieldValue.delete() });
        functions.logger.info('removed stale fcmToken', { uid: recipientUid });
      } else {
        functions.logger.error('failed to send push', { uid: recipientUid, err });
      }
    }
  });
