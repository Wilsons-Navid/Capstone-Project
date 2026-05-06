import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { VertexAI, HarmCategory, HarmBlockThreshold } from '@google-cloud/vertexai';
import * as cors from 'cors';

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

// Initialize Vertex AI
const PROJECT_ID = 'rethicsai'; // Replace with your actual project ID
const LOCATION = 'us-central1'; // Vertex AI location

interface WilsonAIRequest {
  messages: Array<{
    role: 'user' | 'assistant';
    content: string;
  }>;
  userId?: string;
  sessionId?: string;
  contextType?: 'chat' | 'emergency' | 'analysis';
}

interface WilsonAIResponse {
  response: string;
  messageId: string;
  timestamp: number;
  sessionId: string;
  threatLevel?: string;
  recommendations?: string[];
}

// Cybersecurity Knowledge Base for African Context
const AFRICAN_CYBERSECURITY_CONTEXT = {
  mobileMoneyThreats: {
    mpesa: ['SIM swap attacks', 'Fake M-Pesa messages', 'Agent fraud', 'PIN harvesting'],
    mtnMoney: ['USSD code manipulation', 'Fake reversal requests', 'Account takeover'],
    airtelMoney: ['Social engineering', 'Fake customer service calls', 'SMS spoofing']
  },
  commonScams: {
    romance: ['Facebook relationship scams targeting diaspora', 'WhatsApp romance fraud'],
    investment: ['Ponzi schemes via WhatsApp groups', 'Fake cryptocurrency investments'],
    employment: ['Fake job offers requiring registration fees', 'Remote work scams']
  },
  regionalThreats: {
    kenya: ['Huduma Namba phishing', 'KRA tax refund scams', 'County government impersonation'],
    nigeria: ['Yahoo Yahoo recruitment', 'BVN update scams', 'Bank account verification fraud'],
    southAfrica: ['Load shedding scams', 'SASSA grant fraud', 'Municipal billing scams'],
    ghana: ['National ID renewal scams', 'Mobile money tax fraud', 'Gold investment schemes']
  }
};

// Enhanced System Prompt for Wilson AI with African Cybersecurity Focus
const getSystemPrompt = (contextType: string = 'chat'): string => {
  const basePrompt = `You are Wilson, RethicsAI's advanced AI cybersecurity assistant, specifically designed for African communities. You are the continent's leading digital security expert.

CORE IDENTITY:
- Expert in African cybersecurity landscape with deep cultural understanding
- Specialist in mobile-first security (smartphones are primary devices)
- Fluent in local contexts: infrastructure challenges, economic constraints
- Advocate for practical, accessible security solutions
- Supportive mentor focused on empowerment and education

SPECIALIZED KNOWLEDGE AREAS:

🏦 MOBILE MONEY SECURITY:
- M-Pesa, MTN Money, Airtel Money, Orange Money systems
- SIM swap prevention, PIN security, agent verification
- Cross-border mobile money threats and protections
- Integration with traditional banking security

📱 MOBILE-FIRST SECURITY:
- Android security (95% of African market)
- App store safety, side-loading risks
- Data bundle conservation while maintaining security
- Offline security practices for limited connectivity

🌍 REGIONAL THREAT INTELLIGENCE:
- Country-specific scam patterns and prevention
- Local language social engineering tactics
- Cultural context of trust and verification
- Government service impersonation (Huduma, SASSA, etc.)

💼 SME CYBERSECURITY:
- Small business protection with limited budgets
- WhatsApp Business security best practices  
- Digital payment acceptance security
- Employee training for micro-enterprises

🎓 DIGITAL LITERACY EMPOWERMENT:
- Security education for varying tech literacy levels
- Family and community protection strategies
- Building cyber-resilient communities
- Generational bridge-building for security

COMMUNICATION STYLE:
- Use simple, clear language without technical jargon
- Provide step-by-step, actionable guidance
- Include cultural context and local examples
- Show empathy for economic and infrastructure constraints
- Encourage community sharing of security knowledge
- Use positive reinforcement and empowerment messaging

RESPONSE APPROACH:
1. Assess immediate safety needs
2. Provide practical, implementable solutions
3. Explain the "why" behind security practices
4. Offer alternatives for resource-constrained situations
5. Connect to broader community security benefits
6. Include follow-up preventive measures`;

  if (contextType === 'emergency') {
    return basePrompt + `

EMERGENCY MODE ACTIVATED:
You are responding to a potential cybersecurity incident. Prioritize:
1. Immediate threat containment
2. Evidence preservation guidance
3. Local reporting channels and procedures
4. Emotional support and reassurance
5. Step-by-step recovery instructions
6. Prevention of similar future incidents

Be direct, calming, and solution-focused.`;
  }

  if (contextType === 'analysis') {
    return basePrompt + `

ANALYSIS MODE ACTIVATED:
You are analyzing potential threats or suspicious content. Focus on:
1. Detailed threat assessment with African context
2. Specific red flags and indicators
3. Cultural and linguistic analysis of deception tactics
4. Risk level quantification
5. Targeted recommendations based on threat type
6. Regional reporting and response procedures

Provide comprehensive, evidence-based analysis.`;
  }

  return basePrompt;
};

// Wilson AI Enhanced Chat Function with Vertex AI Gemini
export const wilsonAIVertex = functions.https.onRequest((request, response) => {
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

      const { messages, sessionId, contextType = 'chat' }: WilsonAIRequest = request.body;

      if (!messages || !Array.isArray(messages) || messages.length === 0) {
        response.status(400).json({ error: 'Messages array is required' });
        return;
      }

      // Initialize Vertex AI
      const vertexAI = new VertexAI({
        project: PROJECT_ID,
        location: LOCATION,
      });

      // Get Generative Model (Gemini)
      const generativeModel = vertexAI.getGenerativeModel({
        model: 'gemini-1.5-flash', // Cost-effective model
        safetySettings: [
          {
            category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
          {
            category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
        ],
        systemInstruction: {
          parts: [{ text: getSystemPrompt(contextType) }]
        },
        generationConfig: {
          maxOutputTokens: 1000,
          temperature: 0.7,
          topP: 0.8,
          topK: 40,
        },
      });

      // Prepare conversation history
      const conversationHistory = messages.map(msg => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.content }]
      }));

      // Get the latest user message
      const latestMessage = messages[messages.length - 1];

      // Enhanced threat detection and analysis
      const threatAnalysis = await analyzeThreatLevel(latestMessage.content);

      // Generate response with Gemini
      const chat = generativeModel.startChat({
        history: conversationHistory.slice(0, -1), // All messages except the last
      });

      const result = await chat.sendMessage(latestMessage.content);
      const aiResponse = result.response;
      const responseText = aiResponse.text();

      // Generate response data
      const responseData: WilsonAIResponse = {
        response: responseText,
        messageId: admin.firestore().collection('temp').doc().id,
        timestamp: Date.now(),
        sessionId: sessionId || admin.firestore().collection('temp').doc().id,
        threatLevel: threatAnalysis.level,
        recommendations: threatAnalysis.recommendations,
      };

      // Enhanced chat history with threat analysis
      if (authed.uid) {
        try {
          const chatSession = admin.firestore()
            .collection('users')
            .doc(authed.uid)
            .collection('wilsonSessions')
            .doc(responseData.sessionId);

          // Store user message with threat analysis
          await chatSession.collection('messages').add({
            role: 'user',
            content: latestMessage.content,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            threatAnalysis: threatAnalysis,
            contextType,
          });

          // Store AI response
          await chatSession.collection('messages').add({
            role: 'assistant',
            content: responseText,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            model: 'gemini-1.5-flash',
            contextType,
          });

          // Update session metadata
          await chatSession.set({
            lastActivity: admin.firestore.FieldValue.serverTimestamp(),
            messageCount: admin.firestore.FieldValue.increment(2),
            userId: authed.uid,
            model: 'gemini-vertex-ai',
          }, { merge: true });

        } catch (firestoreError) {
          console.warn('Failed to store enhanced chat history:', firestoreError);
        }
      }

      response.json(responseData);

    } catch (error) {
      console.error('Wilson AI Vertex Error:', error);
      
      // Provide helpful fallback response
      const fallbackResponse: WilsonAIResponse = {
        response: `I'm temporarily having connection issues, but I'm still here to help! 🛡️

Here are immediate cybersecurity reminders for Africa:

🔐 **Password Security**: Use unique passwords for banking, social media, and work
📱 **Mobile Money**: Never share your M-Pesa/MTN PIN with anyone, even family
📧 **Scam Alert**: Banks never ask for PINs via SMS or calls
📶 **WiFi Safety**: Avoid banking on public WiFi in malls or cafes
🆔 **Identity Protection**: Verify "winner" messages through official channels

I'll be back to full capacity soon. What specific security topic can I help you with?`,
        messageId: admin.firestore().collection('temp').doc().id,
        timestamp: Date.now(),
        sessionId: 'fallback-session',
        threatLevel: 'LOW',
      };

      response.status(200).json(fallbackResponse); // Return 200 to avoid client-side errors
    }
  });
});

// Advanced Threat Analysis Function
async function analyzeThreatLevel(content: string): Promise<{
  level: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  recommendations: string[];
  indicators: string[];
}> {
  const lowerContent = content.toLowerCase();
  
  // Critical threat indicators
  const criticalIndicators = [
    'hacked', 'compromised', 'stolen money', 'unauthorized transaction',
    'sim swap', 'account takeover', 'identity theft'
  ];
  
  // High threat indicators
  const highIndicators = [
    'suspicious message', 'phishing', 'scam call', 'fake email',
    'unknown transaction', 'won lottery', 'urgent payment'
  ];
  
  // Medium threat indicators
  const mediumIndicators = [
    'password help', 'security question', 'forgot pin',
    'wifi security', 'unknown caller', 'suspicious link'
  ];

  const foundCritical = criticalIndicators.some(indicator => lowerContent.includes(indicator));
  const foundHigh = highIndicators.some(indicator => lowerContent.includes(indicator));
  const foundMedium = mediumIndicators.some(indicator => lowerContent.includes(indicator));

  if (foundCritical) {
    return {
      level: 'CRITICAL',
      recommendations: [
        'Immediately contact your bank/mobile money provider',
        'Change all passwords and PINs',
        'Report to local cybercrime authorities',
        'Monitor all accounts closely'
      ],
      indicators: criticalIndicators.filter(indicator => lowerContent.includes(indicator))
    };
  }

  if (foundHigh) {
    return {
      level: 'HIGH',
      recommendations: [
        'Do not click any links or provide information',
        'Verify through official channels',
        'Report suspicious communications',
        'Enable additional security measures'
      ],
      indicators: highIndicators.filter(indicator => lowerContent.includes(indicator))
    };
  }

  if (foundMedium) {
    return {
      level: 'MEDIUM',
      recommendations: [
        'Follow security best practices',
        'Use official apps and websites only',
        'Enable two-factor authentication',
        'Regular security checkups'
      ],
      indicators: mediumIndicators.filter(indicator => lowerContent.includes(indicator))
    };
  }

  return {
    level: 'LOW',
    recommendations: [
      'Continue practicing good cyber hygiene',
      'Stay informed about current threats',
      'Regular password updates'
    ],
    indicators: []
  };
}

// Real-time Threat Intelligence Function
export const getAfricanThreatIntelligence = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      const authed = await verifyFirebaseUser(request);
      if (!authed) {
        response.status(401).json({ error: 'Unauthorized' });
        return;
      }
      const region = request.query.region as string || 'africa';
      
      // Initialize Vertex AI for threat intelligence
      const vertexAI = new VertexAI({
        project: PROJECT_ID,
        location: LOCATION,
      });

      const model = vertexAI.getGenerativeModel({
        model: 'gemini-1.5-flash',
        systemInstruction: {
          parts: [{ text: `You are a cybersecurity threat intelligence analyst specializing in African digital threats. Provide current, actionable threat intelligence based on the latest trends affecting African users, with focus on mobile money, social media, and mobile-first computing environments.` }]
        }
      });

      const prompt = `Generate current cybersecurity threat intelligence for ${region} in ${new Date().getFullYear()}. Include:

1. Top 5 emerging threats affecting African users this month
2. Mobile money security alerts
3. Social engineering tactics targeting African diaspora  
4. Country-specific scam patterns
5. Recommended protective measures

Format as structured JSON with threat categories, severity levels, and actionable recommendations.`;

      const result = await model.generateContent(prompt);
      const response_text = result.response.text();

      let threatIntelligence;
      try {
        threatIntelligence = JSON.parse(response_text);
      } catch {
        // Fallback structured response
        threatIntelligence = {
          region: region,
          threats: [
            {
              category: 'Mobile Money Fraud',
              severity: 'HIGH',
              description: 'Increased SIM swap attacks targeting mobile money accounts',
              recommendation: 'Enable additional verification for all mobile money transactions'
            }
          ],
          generated_at: new Date().toISOString(),
          source: 'Wilson AI Threat Intelligence'
        };
      }

      response.json({
        ...threatIntelligence,
        region,
        timestamp: Date.now(),
        expires_at: Date.now() + (6 * 60 * 60 * 1000), // 6 hours
      });

    } catch (error) {
      console.error('Threat Intelligence Error:', error);
      response.status(500).json({
        error: 'Failed to generate threat intelligence',
        timestamp: Date.now()
      });
    }
  });
});

// Cybersecurity Training Content Generator
export const generateSecurityTraining = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      const authed = await verifyFirebaseUser(request);
      if (!authed) {
        response.status(401).json({ error: 'Unauthorized' });
        return;
      }
      const { topic, level, language = 'english' } = request.body;

      const vertexAI = new VertexAI({
        project: PROJECT_ID,
        location: LOCATION,
      });

      const model = vertexAI.getGenerativeModel({
        model: 'gemini-1.5-pro', // More capable model for content generation
        systemInstruction: {
          parts: [{ text: `You are Wilson, a cybersecurity education specialist creating training content for African users. Create engaging, culturally relevant, and practical cybersecurity training materials that consider local context, infrastructure limitations, and cultural nuances.` }]
        }
      });

      const prompt = `Create comprehensive cybersecurity training content for topic: "${topic}" at "${level}" level in ${language}.

Include:
1. Learning objectives
2. Interactive scenarios with African context
3. Practical exercises using local examples (M-Pesa, local banks, etc.)
4. Assessment questions
5. Real-world case studies from African cybersecurity incidents
6. Community-sharing activities
7. Follow-up resources and tools

Make it engaging, practical, and culturally relevant for African learners.`;

      const result = await model.generateContent(prompt);
      const trainingContent = result.response.text();

      response.json({
        topic,
        level,
        language,
        content: trainingContent,
        generated_at: Date.now(),
        expires_at: Date.now() + (7 * 24 * 60 * 60 * 1000), // 7 days
        version: '1.0'
      });

    } catch (error) {
      console.error('Training Content Generation Error:', error);
      response.status(500).json({
        error: 'Failed to generate training content',
        timestamp: Date.now()
      });
    }
  });
});
