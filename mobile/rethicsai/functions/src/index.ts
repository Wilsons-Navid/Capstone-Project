import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';
import * as cors from 'cors';

// Import the new Wilson AI Vertex functions
export { 
  wilsonAIVertex, 
  getAfricanThreatIntelligence, 
  generateSecurityTraining 
} from './wilsonAIVertexModel';

admin.initializeApp();

// Restrictive CORS with optional allowlist
const allowedOriginsCfg = (functions.config() as any)?.app?.allowed_origins as string | undefined;
const allowedOrigins = allowedOriginsCfg ? allowedOriginsCfg.split(',').map(s => s.trim()) : [];
const corsHandler = cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    if (allowedOrigins.length === 0 || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  }
});

async function verifyFirebaseUser(req: functions.Request): Promise<{ uid: string } | null> {
  const authHeader = (req.headers['authorization'] || req.headers['Authorization']) as string | undefined;
  if (!authHeader) return null;
  const m = /^Bearer\s+(.+)$/.exec(authHeader);
  if (!m) return null;
  try {
    const decoded = await admin.auth().verifyIdToken(m[1]);
    return { uid: decoded.uid };
  } catch {
    return null;
  }
}

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface WilsonChatRequest {
  messages: ChatMessage[];
  userId?: string;
  sessionId?: string;
}

interface WilsonChatResponse {
  response: string;
  messageId: string;
  timestamp: number;
  sessionId: string;
}

// Wilson AI Chat Function - Streams messages to OpenAI GPT-4
export const wilsonChat = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        response.status(405).send('Method Not Allowed');
        return;
      }

      const authed = await verifyFirebaseUser(request);
      if (!authed) {
        response.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { messages, sessionId }: WilsonChatRequest = request.body;

      if (!messages || !Array.isArray(messages) || messages.length === 0) {
        response.status(400).json({ error: 'Messages array is required' });
        return;
      }

      // System prompt for Wilson AI - Cybersecurity focused assistant
      const systemPrompt: ChatMessage = {
        role: 'system',
        content: `You are Wilson, RethicsAI's advanced cybersecurity assistant designed specifically for African communities. You are knowledgeable, helpful, and culturally aware.

Key aspects of your personality and knowledge:
- Cybersecurity expert with deep understanding of threats facing Africa
- Familiar with mobile money systems (M-Pesa, Airtel Money, etc.)
- Understand local context: limited internet infrastructure, smartphone-first usage
- Speak in a friendly, accessible way without being overly technical
- Provide practical, actionable security advice
- Aware of social engineering tactics common in African regions
- Know about common scams targeting African users
- Understanding of local languages and cultural nuances

When helping users:
1. Ask clarifying questions if needed
2. Provide step-by-step guidance
3. Explain WHY security measures matter
4. Offer alternatives for low-resource situations
5. Be encouraging and supportive
6. Use relevant local examples when possible

Focus areas:
- Password security and management
- Mobile device security
- Social media safety
- Email and messaging security
- Online shopping and payment security
- WiFi and network security
- Scam and fraud prevention
- Identity protection
- Business cybersecurity for SMEs
- Incident reporting and response

Always be helpful, accurate, and prioritize user safety and security education.`
      };

      // Prepare messages for OpenAI
      const fullMessages: ChatMessage[] = [systemPrompt, ...messages];

      // Call OpenAI API
      const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: fullMessages,
        max_tokens: 1000,
        temperature: 0.7,
        stream: false, // We'll implement streaming later if needed
      });

      const aiResponse = completion.choices[0]?.message?.content || 'I apologize, but I could not generate a response at this time.';

      // Generate response data
      const responseData: WilsonChatResponse = {
        response: aiResponse,
        messageId: admin.firestore().collection('temp').doc().id,
        timestamp: Date.now(),
        sessionId: sessionId || admin.firestore().collection('temp').doc().id,
      };

      // Store chat history in Firestore (optional)
      if (authed.uid) {
        try {
          await admin.firestore()
            .collection('users')
            .doc(authed.uid)
            .collection('chatSessions')
            .doc(responseData.sessionId)
            .collection('messages')
            .add({
              ...messages[messages.length - 1], // User's last message
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

          await admin.firestore()
            .collection('users')
            .doc(authed.uid)
            .collection('chatSessions')
            .doc(responseData.sessionId)
            .collection('messages')
            .add({
              role: 'assistant',
              content: aiResponse,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
        } catch (firestoreError) {
          console.warn('Failed to store chat history:', firestoreError);
          // Continue with response even if storage fails
        }
      }

      response.json(responseData);

    } catch (error) {
      console.error('Wilson Chat Error:', error);
      
      let errorMessage = 'An unexpected error occurred';
      if (error instanceof Error) {
        errorMessage = error.message;
      }

      response.status(500).json({ 
        error: 'Internal server error',
        message: errorMessage,
        timestamp: Date.now()
      });
    }
  });
});

// Function to analyze suspicious content
export const analyzeSuspiciousContent = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== 'POST') {
        response.status(405).send('Method Not Allowed');
        return;
      }

      const authed = await verifyFirebaseUser(request);
      if (!authed) {
        response.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { content, contentType } = request.body;

      if (!content) {
        response.status(400).json({ error: 'Content is required' });
        return;
      }

      // Use OpenAI to analyze suspicious content
      const analysisPrompt = `Analyze the following ${contentType || 'content'} for potential cybersecurity threats, scams, or malicious intent. 
      Focus on threats common in African contexts including:
      - Mobile money scams
      - Social engineering
      - Phishing attempts
      - Fake job offers
      - Romance scams
      - Investment frauds
      
      Content to analyze:
      "${content}"
      
      Provide:
      1. Threat level (LOW, MEDIUM, HIGH, CRITICAL)
      2. Threat types identified
      3. Specific red flags found
      4. Recommendations for the user
      
      Respond in JSON format.`;

      const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'You are a cybersecurity analyst specializing in African digital threats. Provide detailed, actionable analysis.'
          },
          {
            role: 'user',
            content: analysisPrompt
          }
        ],
        max_tokens: 800,
        temperature: 0.2,
      });

      const analysisResult = completion.choices[0]?.message?.content;
      
      // Try to parse as JSON, fallback to structured response
      let structuredResult;
      try {
        structuredResult = JSON.parse(analysisResult || '{}');
      } catch {
        structuredResult = {
          threatLevel: 'MEDIUM',
          analysis: analysisResult,
          timestamp: Date.now()
        };
      }

      response.json({
        ...structuredResult,
        analysisId: admin.firestore().collection('temp').doc().id,
        timestamp: Date.now(),
      });

    } catch (error) {
      console.error('Content Analysis Error:', error);
      response.status(500).json({ 
        error: 'Failed to analyze content',
        timestamp: Date.now()
      });
    }
  });
});

// Function to get cybersecurity insights
export const getCyberInsights = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      if (request.method !== 'GET') {
        response.status(405).send('Method Not Allowed');
        return;
      }

      const authed = await verifyFirebaseUser(request);
      if (!authed) {
        response.status(401).json({ error: 'Unauthorized' });
        return;
      }

      // Generate daily cybersecurity insights for African users
      const insightsPrompt = `Generate 3-5 current cybersecurity tips and insights specifically relevant to African users in ${new Date().getFullYear()}. 

      Focus on:
      - Mobile-first security practices
      - Current threat landscape in Africa
      - Practical tips for limited-resource environments  
      - Mobile money security
      - Social media safety
      - Business email security for SMEs

      Format as a JSON array of insights with: title, description, category, priority, actionable_tip.`;

      const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'You are a cybersecurity expert providing daily insights for African technology users. Be practical and culturally relevant.'
          },
          {
            role: 'user',
            content: insightsPrompt
          }
        ],
        max_tokens: 1200,
        temperature: 0.8,
      });

      const insightsResult = completion.choices[0]?.message?.content;
      
      let insights;
      try {
        insights = JSON.parse(insightsResult || '[]');
      } catch {
        insights = [{
          title: 'Daily Security Reminder',
          description: 'Stay vigilant online and keep your devices updated.',
          category: 'general',
          priority: 'medium',
          actionable_tip: 'Check for app updates today.'
        }];
      }

      response.json({
        insights,
        generated_at: Date.now(),
        expires_at: Date.now() + (24 * 60 * 60 * 1000), // 24 hours
      });

    } catch (error) {
      console.error('Cyber Insights Error:', error);
      response.status(500).json({ 
        error: 'Failed to generate insights',
        timestamp: Date.now()
      });
    }
  });
});
