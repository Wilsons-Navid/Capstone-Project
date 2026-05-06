# Firebase Vertex AI Configuration Guide

## Wilson AI Enhanced Model Deployment

This guide covers the setup and deployment of the enhanced Wilson AI model using Vertex AI Gemini integration.

## Prerequisites

### 1. Google Cloud Project Setup
```bash
# Enable required APIs
gcloud services enable aiplatform.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable firestore.googleapis.com
```

### 2. Firebase Project Configuration
- Ensure you're on the **Blaze Plan** (Pay-as-you-go) for Vertex AI access
- Project ID: `rethicsai` (update in wilsonAIVertexModel.ts if different)
- Location: `us-central1` (recommended for Vertex AI)

## Deployment Steps

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Build Functions
```bash
npm run build
```

### 3. Deploy to Firebase
```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:wilsonAIVertex
firebase deploy --only functions:getAfricanThreatIntelligence  
firebase deploy --only functions:generateSecurityTraining
```

## Available Functions

### 1. Wilson AI Vertex Chat
**Endpoint**: `wilsonAIVertex`
**Method**: POST
**Features**:
- Advanced Gemini 1.5 Flash model
- African cybersecurity specialization
- Real-time threat level assessment
- Enhanced conversation tracking

### 2. African Threat Intelligence
**Endpoint**: `getAfricanThreatIntelligence`
**Method**: GET
**Features**:
- Region-specific threat updates
- Mobile money security alerts
- Social engineering pattern analysis
- Country-specific scam identification

### 3. Security Training Generator
**Endpoint**: `generateSecurityTraining`
**Method**: POST
**Features**:
- Customized training content
- Multiple proficiency levels
- Multi-language support
- African context integration

## Cost Optimization

### Model Selection
- **Gemini 1.5 Flash**: Cost-effective for regular chat (~$0.075/1K tokens)
- **Gemini 1.5 Pro**: Advanced analysis (~$3.50/1K tokens)

### Usage Patterns
- Custom responses for common queries (FREE)
- AI responses for complex analysis (PAID)
- Cached threat intelligence (6-hour refresh)
- Training content (7-day cache)

### Estimated Monthly Costs
- **Light usage** (1,000 interactions): ~$5-10
- **Medium usage** (5,000 interactions): ~$25-50  
- **Heavy usage** (20,000 interactions): ~$100-200

## Security Configuration

### App Check Integration
- Enabled for all Vertex AI endpoints
- Protects against unauthorized usage
- Validates app authenticity

### Safety Settings
```typescript
safetySettings: [
  {
    category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  }
]
```

## Monitoring and Analytics

### Firebase Functions Logs
```bash
firebase functions:log --only wilsonAIVertex
```

### Vertex AI Monitoring
- Access Google Cloud Console > Vertex AI > Model Garden
- Monitor token usage and costs
- Set up billing alerts

## Client Integration

### Update Wilson AI Service
Replace existing `wilson_ai_service.dart` imports:

```dart
import '../services/wilson_ai_vertex_service.dart';

// Enhanced Wilson AI with threat analysis
final wilsonAI = WilsonAIVertexService();

// Chat with enhanced capabilities
final response = await wilsonAI.chatWithWilsonVertex(
  messages: messages,
  contextType: WilsonContextType.emergency, // For urgent situations
);
```

### Threat Level Integration
```dart
// Automatic threat assessment
final threatLevel = wilsonAI.analyzeMessageThreatLevel(userMessage);

// Respond based on threat level
if (threatLevel == ThreatLevel.critical) {
  // Show emergency response UI
  showEmergencyDialog();
}
```

## Testing

### Local Testing
```bash
cd functions
npm run serve
```

### Production Testing
Use Firebase Functions emulator with real Vertex AI calls:
```bash
firebase emulators:start --only functions
```

## Fallback Strategy

The system includes multiple fallback layers:
1. **Primary**: Vertex AI Gemini responses
2. **Secondary**: Custom response templates
3. **Tertiary**: Basic security guidance

This ensures Wilson AI remains functional even during API outages.

## African Cybersecurity Focus

### Specialized Knowledge Areas
- Mobile money systems (M-Pesa, MTN, Airtel)
- Regional scam patterns by country
- Infrastructure-aware security advice
- Cultural context integration
- Multi-language support preparation

### Regional Threat Database
- Kenya: Huduma Namba, KRA, M-Pesa scams
- Nigeria: BVN, Yahoo Yahoo, bank fraud
- South Africa: Load shedding, SASSA, municipal scams
- Ghana: National ID, mobile money tax, gold investment fraud

## Next Steps

1. Deploy the enhanced functions
2. Test with various threat scenarios
3. Monitor usage and costs
4. Gather user feedback
5. Iterate on African-specific content
6. Expand multi-language support

The Wilson AI model is now ready to provide world-class cybersecurity assistance tailored specifically for African users! 🛡️🌍