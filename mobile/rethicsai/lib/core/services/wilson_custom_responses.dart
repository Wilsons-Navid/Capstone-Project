import 'dart:math';
import 'package:easy_localization/easy_localization.dart';

class WilsonCustomResponses {
  static final Random _random = Random();

  // Quick suggestion responses - triggered when cards are clicked
  static const Map<String, List<String>> _quickResponses = {
    // Password Security
    'password_security': [
      'Strong passwords are your first line of defense! 🔐\n\nHere are my top tips for African users:\n\n• Use 12+ characters with mixed case, numbers, and symbols\n• Never use personal info like your name, birthdate, or phone number\n• Avoid common African names or places\n• Consider using a passphrase like "MyM-Pesa#Is\$ecure2024!"\n• Use different passwords for banking, social media, and work accounts\n\nRemember: Your M-Pesa PIN and banking passwords should be unique and never shared!',
      
      'Let me help you create bulletproof passwords! 💪\n\nFor maximum security in Africa:\n\n✅ THINGS TO DO:\n• Mix languages: "Habari2024#Secure!"\n• Use memorable phrases: "I love Lagos but Nairobi is better 123!"\n• Enable 2FA on all banking and social apps\n• Use password managers like Bitwarden\n\n❌ THINGS TO AVOID:\n• Use "123456" or "password"\n• Share your banking PINs via SMS\n• Use the same password for multiple accounts\n• Write passwords on paper\n\nStay safe out there! 🛡️'
    ],

    // Phishing Awareness
    'phishing_awareness': [
      'Phishing attacks are rampant in Africa! 🎣 Let me help you spot them:\n\n🚨 RED FLAGS TO WATCH FOR:\n• Urgent messages about "account suspension"\n• Requests for M-Pesa PINs or bank details\n• Links from unknown senders\n• Poor English/local language grammar\n• Pressure to "act immediately"\n\n✅ SAFETY TIPS TO FOLLOW:\n• Banks NEVER ask for PINs via SMS/email\n• Always verify by calling your bank directly\n• Check URLs carefully (not "M-pesa.com" but "m-pesa.co.ke")\n• When in doubt, don\'t click!\n\nProtect your hard-earned money! 💰',
      
      'Scammers are targeting African mobile money users! 📱\n\n🎭 COMMON SCAMMER TRICKS:\n• Fake "You\'ve won money" messages\n• Impersonating Safaricom, MTN, or Airtel\n• "Emergency" calls asking for airtime\n• Fake job offers requiring "registration fees"\n\n🛡️ HOW TO STAY SAFE:\n• Never give your M-Pesa PIN to anyone\n• Verify winners with official channels\n• Be suspicious of "too good to be true" offers\n• Report suspicious numbers to your network\n\nTrust your instincts - if it feels wrong, it probably is! 🧠'
    ],

    // Social Media Safety
    'social_media_safety': [
      'Social media can be dangerous if not used wisely! 📱\n\n🔒 PRIVACY ESSENTIALS:\n• Limit personal info on your profile\n• Don\'t post your location in real-time\n• Be careful with photos showing expensive items\n• Check your privacy settings regularly\n• Think before you share\n\n🌍 AFRICAN-SPECIFIC TIPS:\n• Don\'t post about travel plans (burglary risk)\n• Be cautious of friend requests from strangers\n• Avoid posting about salary or business income\n• Don\'t share family photos with house numbers visible\n\nSocial media should connect us safely! 🤝',
      
      'Let\'s make your social media bulletproof! 🛡️\n\n💡 SMART PRACTICES:\n• Use strong, unique passwords for each platform\n• Enable 2FA on Facebook, Instagram, Twitter\n• Regularly review tagged photos\n• Be selective with friend/follower requests\n• Avoid clicking suspicious links in DMs\n\n⚠️ WATCH OUT FOR:\n• Romance scams (especially on dating apps)\n• Fake news that could cause panic\n• Cryptocurrency scams promising quick riches\n• Requests for money from "friends in trouble"\n\nStay connected, stay protected! ✨'
    ],

    // Mobile Money Security
    'mobile_money_security': [
      'Mobile money security is CRITICAL in Africa! 💳\n\n📱 M-PESA/MOBILE MONEY SAFETY:\n• Never share your PIN with ANYONE\n• Always verify recipient numbers before sending\n• Use secure networks, avoid public WiFi for transactions\n• Set up transaction notifications\n• Regularly check your statement\n\n🚨 SCAM ALERTS:\n• No legitimate service asks for PINs via SMS\n• Beware of "system upgrade" messages\n• Don\'t reverse transactions for strangers\n• Report suspicious agents to your provider\n\nYour money, your responsibility! 💪',
      
      'Protecting your mobile money is protecting your future! 🏦\n\n✅ BEST PRACTICES:\n• Keep your phone locked with PIN/biometrics\n• Register SIM card in your name only\n• Don\'t lend your phone for transactions\n• Use official apps only (not links from SMS)\n• Keep small amounts for daily use, save rest in bank\n\n🔴 DANGER SIGNS:\n• Unknown deductions from your account\n• SMS asking to confirm transactions you didn\'t make\n• Agents asking for additional fees\n• Pressure to complete transactions quickly\n\nBe smart with your money! 🧠💰'
    ],

    // Online Shopping
    'online_shopping_safety': [
      'Online shopping safely in Africa requires extra caution! 🛒\n\n🛡️ SECURE SHOPPING TIPS:\n• Shop only on reputable sites (Jumia, Kilimall, etc.)\n• Look for HTTPS and security badges\n• Read reviews from verified buyers\n• Use secure payment methods\n• Avoid deals that seem too good to be true\n\n🚩 RED FLAGS:\n• Requests for M-Pesa PINs\n• No physical address or contact info\n• Only payment option is mobile money\n• Pressure to pay immediately\n• Unrealistic discounts (90% off luxury items)\n\nSmart shopping keeps you safe! ✅',
      
      'Let me help you shop online safely! 🛍️\n\n📝 PRE-PURCHASE CHECKLIST:\n• Verify the seller\'s reputation and reviews\n• Check return/refund policies\n• Use payment methods with buyer protection\n• Screenshot product descriptions and prices\n• Verify delivery details\n\n💳 PAYMENT SAFETY:\n• Use credit cards when possible (better protection)\n• For mobile money, use official app interfaces\n• Never pay via gift cards or crypto\n• Keep transaction receipts\n\nHappy and safe shopping! 🎉'
    ],

    // WiFi Security
    'wifi_security': [
      'WiFi security is often overlooked but crucial! 📶\n\n⚠️ PUBLIC WIFI DANGERS:\n• Hackers can intercept your data\n• Fake hotspots mimic legitimate ones\n• Banking info can be stolen\n• Personal messages can be read\n\n🛡️ STAY SAFE:\n• Use VPNs on public networks\n• Avoid banking on public WiFi\n• Forget networks after use\n• Turn off auto-connect\n• Use mobile data for sensitive tasks\n\n🏠 HOME WIFI SECURITY:\n• Change default router password\n• Use WPA3 encryption\n• Hide your network name (SSID)\n• Update router firmware regularly\n\nSecure connections only! 🔒',
      
      'WiFi security mistakes can cost you! 💸\n\n🏨 COMMON AFRICAN SCENARIOS:\n• Hotel WiFi in tourist areas (often unsecured)\n• Mall/restaurant hotspots (easy to fake)\n• Office networks (may not be secure)\n• Neighbor\'s "free" WiFi (could be a trap)\n\n🛡️ PROTECTION STRATEGIES:\n• Use your mobile data for important stuff\n• If you must use public WiFi, use a VPN\n• Check network names carefully ("Starbucks_Free" vs "Starbucks Free")\n• Turn off file sharing on public networks\n• Log out of all accounts when done\n\nBetter safe than sorry! 🛡️'
    ],

    // General Cybersecurity
    'general_security': [
      'Cybersecurity in Africa has unique challenges! 🌍\n\n⚡ KEY THREATS:\n• SIM swap attacks targeting mobile money\n• Romance scams on social media\n• Fake job opportunities\n• Business email compromise\n• Ransomware targeting small businesses\n\n🛡️ PROTECTION BASICS:\n• Keep devices updated\n• Use antivirus software\n• Back up important data\n• Be skeptical of unsolicited offers\n• Educate family members about scams\n\nTogether, we can build a safer digital Africa! 🚀',
      
      'Your cybersecurity journey starts here! 🎯\n\n🔄 DAILY HABITS FOR SAFETY:\n• Check your bank/mobile money statements weekly\n• Don\'t click on suspicious links\n• Keep your apps updated\n• Use strong, unique passwords\n• Think before you share personal info\n\n💼 FOR BUSINESS OWNERS:\n• Train employees on phishing\n• Use business-grade security solutions\n• Backup customer data securely\n• Have an incident response plan\n• Consider cyber insurance\n\nSecurity is everyone\'s responsibility! 👥'
    ],

    // Incident Response
    'incident_response': [
      'Been hacked or scammed? Don\'t panic! 🆘\n\nIMMEDIATE ACTIONS:\n• Change all passwords NOW\n• Contact your bank/mobile money provider\n• Document everything (screenshots, transaction IDs)\n• Report to local authorities\n• Freeze affected accounts\n\nREPORTING CHANNELS:\n• Kenya: Report to CA (Communications Authority)\n• Nigeria: Contact EFCC or police\n• South Africa: Use SAFPS or SAPS\n• Ghana: Report to Bank of Ghana or CID\n\nDON\'T:\n• Pay ransoms or "recovery fees"\n• Share incident details publicly\n• Try to hack back\n\nWe\'re here to help you recover! 💪',
      
      'Incident response is critical - let me guide you! 🚨\n\nIF YOUR PHONE IS COMPROMISED:\n• Contact your network provider immediately\n• Block your SIM card\n• Change all account passwords from another device\n• Review recent transactions\n• Enable 2FA on all accounts\n\nIF YOUR BANK/MOBILE MONEY IS COMPROMISED:\n• Call your bank\'s fraud hotline\n• Dispute unauthorized transactions\n• Get new cards/PINs\n• Monitor statements closely\n• File a police report\n\nPREVENTION FOR NEXT TIME:\n• Regular security checkups\n• Keep software updated\n• Use security apps\n\nYou\'ll get through this! 🤝'
    ]
  };

  // Contextual responses based on keywords in user messages
  static const Map<String, List<String>> _contextualResponses = {
    'mpesa|mobile money|safaricom|mtn|airtel|banking|bank': [
      'Mobile money security is my specialty! 📱💰\n\nI see you\'re asking about mobile money. Here\'s what you need to know:\n\n• Never share your PIN, even with family\n• Always verify recipient numbers before sending\n• Be wary of "reverse transaction" requests\n• Use official apps only\n• Report suspicious activities immediately\n\nWhat specific mobile money concern can I help you with?'
    ],
    
    'whatsapp|telegram|facebook|instagram|twitter': [
      'Social media safety is crucial in Africa! 📱\n\nI notice you\'re asking about social platforms. Key safety tips:\n\n• Adjust privacy settings regularly\n• Be cautious of friend requests from strangers\n• Don\'t share location in real-time\n• Watch out for romance scams\n• Verify news before sharing\n\nWhich social media security aspect concerns you most?'
    ],

    'bank|banking|account|atm': [
      'Banking security is vital for your financial future! 🏦\n\nBanking safety essentials:\n\n• Use strong, unique passwords for online banking\n• Enable SMS/email alerts for all transactions\n• Never bank on public WiFi\n• Cover your PIN at ATMs\n• Report suspicious activities immediately\n\nWhat banking security question can I help you with?'
    ],

    'scam|fraud|hack|suspicious': [
      'Staying alert to scams is smart! 🔍\n\nCommon scams in Africa:\n\n• "You\'ve won a lottery" messages\n• Fake job offers requiring fees\n• Romance scams on dating apps\n• Business email compromise\n• Fake tech support calls\n\nIf you\'ve encountered something suspicious, I can help you identify if it\'s a scam and what to do next. What happened?'
    ],

    'password|pin|otp|secure|protect|safety': [
      'Strong authentication is your digital fortress! 🔐\n\nPassword/PIN best practices:\n\n• Use unique passwords for each account\n• Include numbers, symbols, and mixed case\n• Never share OTPs or PINs\n• Enable 2FA where possible\n• Use password managers\n\nNeed help creating a strong password strategy?'
    ],
    
    'wifi|network|internet|connection': [
      'WiFi security is crucial, especially in Africa! 📶\n\nPublic WiFi safety tips:\n\n• Avoid banking on public networks\n• Use VPN when possible\n• Turn off auto-connect to unknown networks\n• Verify network names carefully\n• Use mobile data for sensitive tasks\n\nNeed specific advice about WiFi security?'
    ],
    
    'help|how|what|guide|tips|advice': [
      'I\'m here to help with all your cybersecurity needs! 🛡️\n\n🎯 I SPECIALIZE IN:\n\n• Mobile money protection (M-Pesa, MTN, Airtel)\n• Password and authentication security\n• Scam and phishing detection\n• Social media privacy\n• WiFi and network safety\n• Emergency incident response\n\nWhat specific cybersecurity topic interests you most?'
    ]
  };

  // Get response for quick suggestion cards
  static String getQuickResponse(String category) {
    final responses = _quickResponses[category];
    if (responses == null || responses.isEmpty) {
      return _getDefaultResponse(category);
    }
    return responses[_random.nextInt(responses.length)];
  }

  // Get contextual response based on user message
  static String? getContextualResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Check for emergency keywords first
    final emergencyKeywords = ['hack', 'scam', 'fraud', 'stolen', 'emergency', 'help', 'urgent', 'lost money', 'compromised', 'suspicious'];
    for (final keyword in emergencyKeywords) {
      if (lowerMessage.contains(keyword)) {
        if (lowerMessage.contains('hack') || lowerMessage.contains('compromised')) {
          return getEmergencyResponse('hacked');
        } else if (lowerMessage.contains('scam') || lowerMessage.contains('fraud') || lowerMessage.contains('lost money')) {
          return getEmergencyResponse('scammed');
        } else {
          return getEmergencyResponse('general');
        }
      }
    }
    
    // Regular contextual responses
    for (final entry in _contextualResponses.entries) {
      final patterns = entry.key.split('|');
      for (final pattern in patterns) {
        if (lowerMessage.contains(pattern)) {
          final responses = entry.value;
          return responses[_random.nextInt(responses.length)];
        }
      }
    }
    
    return null; // No contextual response found
  }

  // Get emergency/urgent responses
  static String getEmergencyResponse(String emergencyType) {
    switch (emergencyType.toLowerCase()) {
      case 'hacked':
        return '🚨 URGENT: Account Compromised Response\n\nIf your account has been hacked:\n\n1. IMMEDIATELY change all passwords\n2. Contact your bank/mobile money provider\n3. Enable 2FA on all accounts\n4. Check for unauthorized transactions\n5. Run antivirus scans\n6. Report to local cybercrime unit\n\nDo NOT:\n• Pay any ransom demands\n• Use the compromised device for banking\n• Share the incident on social media\n\nNeed specific help with any of these steps?';
      
      case 'scammed':
        return '🚨 SCAM VICTIM - Immediate Action Required\n\nIf you\'ve been scammed:\n\n1. STOP all further communication with scammers\n2. Document everything (screenshots, numbers, emails)\n3. Contact your bank immediately\n4. Report to police and file a case\n5. Warn friends/family about the scam\n6. Monitor accounts closely\n\nEMERGENCY CONTACTS:\n• Kenya: 0800 722 203 (CA)\n• Nigeria: 199 (EFCC)\n• South Africa: 0860 123 123 (FIC)\n\nHow much did you lose? What type of scam was it?';
      
      case 'identity_theft':
        return '🚨 IDENTITY THEFT - Critical Response Needed\n\nIf your identity is being misused:\n\n1. Contact all your banks immediately\n2. Get new ID documents if compromised\n3. Alert credit bureaus\n4. Monitor all accounts daily\n5. File police report with evidence\n6. Consider legal action\n\nPROTECT YOURSELF:\n• Freeze all accounts temporarily\n• Change all passwords\n• Enable fraud alerts\n• Don\'t share new details until secure\n\nThis is serious - do you need help with specific steps?';
      
      default:
        return 'I understand you\'re dealing with a cybersecurity emergency. Please describe exactly what happened so I can provide specific guidance. Remember:\n\n• Stay calm\n• Don\'t make any payments\n• Document everything\n• Act quickly but thoughtfully\n\nWhat\'s the exact situation you\'re facing?';
    }
  }

  // Default responses for unknown categories
  static String _getDefaultResponse(String category) {
    return 'Thanks for asking about $category! 🤖\n\nI\'m Wilson, your cybersecurity assistant. While I have extensive knowledge about cybersecurity in Africa, I\'d like to understand your specific concern better.\n\nCould you tell me:\n• What specific aspect interests you?\n• Are you facing a particular challenge?\n• Do you need help with prevention or incident response?\n\nI\'m here to help keep you safe online! 🛡️';
  }

  // Get encouraging/motivational responses
  static List<String> getMotivationalResponses() {
    return [
      'You\'re taking the right steps to protect yourself online! 💪 Cybersecurity is a journey, not a destination.',
      'Every security measure you implement makes you stronger! 🛡️ Africa\'s digital future depends on users like you.',
      'Knowledge is power in cybersecurity! 🧠 You\'re building digital resilience for yourself and your community.',
      'Stay vigilant, stay secure! 👁️ Your awareness protects not just you, but everyone around you.',
      'Together, we\'re making African cyberspace safer! 🌍 One educated user at a time.'
    ];
  }

  // Get random cybersecurity tip
  static String getRandomTip() {
    final tips = [
      '💡 TIP: Update your apps regularly - many updates contain security fixes!',
      '💡 TIP: Use different passwords for banking, social media, and work accounts.',
      '💡 TIP: Be extra cautious of public WiFi - use your mobile data for important tasks.',
      '💡 TIP: If an offer seems too good to be true, it probably is!',
      '💡 TIP: Your bank will never ask for your PIN via SMS or call.',
      '💡 TIP: Enable 2FA on all your important accounts for extra security.',
      '💡 TIP: Regularly check your mobile money and bank statements.',
      '💡 TIP: Don\'t click on links from unknown senders.',
      '💡 TIP: Keep your antivirus software updated and running.',
      '💡 TIP: Back up your important data regularly.',
    ];
    
    return tips[_random.nextInt(tips.length)];
  }

  // Get weather-appropriate security reminder
  static String getWeatherSecurityReminder() {
    final reminders = [
      '⛈️ Storm Warning: During power outages, be extra careful of phishing SMS claiming to help with electricity issues!',
      '☀️ Hot Weather Reminder: Don\'t leave your phone in direct sunlight - overheating can cause security app malfunctions.',
      '🌧️ Rainy Season Alert: Flooding can affect network towers - beware of scam SMS claiming network "recovery fees".',
      '🌪️ Weather Alert: During emergencies, scammers often exploit chaos - verify all emergency-related messages.',
    ];
    
    return reminders[_random.nextInt(reminders.length)];
  }

  // Get location-specific advice (if location is detected)
  static String getLocationSpecificAdvice(String country) {
    switch (country.toLowerCase()) {
      case 'kenya':
        return '🇰🇪 Kenya-Specific Security:\n\n• M-Pesa: Beware of "Fuliza limit increase" scams\n• Be cautious of fake Huduma Namba messages\n• Report cybercrimes to Communications Authority\n• Watch out for fake KRA tax refund messages';
      
      case 'nigeria':
        return '🇳🇬 Nigeria-Specific Security:\n\n• Bank transfer limits have changed - verify with your bank\n• Beware of fake BVN update messages\n• Report cybercrimes to EFCC\n• Be extra cautious of "Yahoo Yahoo" recruitment scams';
      
      case 'south africa':
        return '🇿🇦 South Africa-Specific Security:\n\n• Load shedding scams are common - verify Eskom messages\n• Be cautious of fake SASSA grant messages\n• Report cybercrimes to SAPS\n• Watch out for hijacking coordination via messaging apps';
      
      case 'ghana':
        return '🇬🇭 Ghana-Specific Security:\n\n• Mobile money tax changes - verify with your provider\n• Be cautious of fake national ID renewal messages\n• Report cybercrimes to CID\n• Watch out for fake gold investment schemes online';
      
      default:
        return '🌍 General African Security:\n\n• Mobile money security is crucial across Africa\n• Be cautious of cross-border investment scams\n• Verify all government-related messages\n• Report cybercrimes to local authorities';
    }
  }
}