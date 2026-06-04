import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyContactsService {
  static const String _collection = 'emergency_contacts';
  
  static CollectionReference get _contacts =>
      FirebaseFirestore.instance.collection(_collection);

  // Get emergency contacts by country
  static Future<List<EmergencyContact>> getContactsByCountry(String country) async {
    try {
      final snapshot = await _contacts
          .where('country', isEqualTo: country)
          .orderBy('priority', descending: true)
          .get();
      
      final results = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmergencyContact.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
      // Fall back to bundled defaults when this country isn't seeded in Firestore yet.
      return results.isEmpty ? _getDefaultContactsForCountry(country) : results;
    } catch (e) {
      // Return default contacts if Firebase fails
      return _getDefaultContactsForCountry(country);
    }
  }

  /// Countries that have bundled authority contacts (for pickers/dropdowns).
  static List<String> supportedCountries() {
    final set = <String>{for (final c in _getAllDefaultContacts()) c.country};
    return set.toList()..sort();
  }

  // Get all available countries
  static Future<List<String>> getAvailableCountries() async {
    try {
      final snapshot = await _contacts.get();
      final countries = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final country = data['country'] as String?;
        if (country != null) {
          countries.add(country);
        }
      }
      
      return countries.toList()..sort();
    } catch (e) {
      return ['Nigeria', 'Kenya', 'South Africa', 'Ghana', 'Uganda'];
    }
  }

  // Search contacts
  static Future<List<EmergencyContact>> searchContacts(String query) async {
    try {
      final snapshot = await _contacts.get();
      final results = <EmergencyContact>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final contact = EmergencyContact.fromJson({
          ...data,
          'id': doc.id,
        });
        
        if (contact.name.toLowerCase().contains(query.toLowerCase()) ||
            contact.department.toLowerCase().contains(query.toLowerCase()) ||
            contact.description.toLowerCase().contains(query.toLowerCase())) {
          results.add(contact);
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search contacts: $e');
    }
  }

  // Get contacts by type
  static Future<List<EmergencyContact>> getContactsByType(ContactType type) async {
    try {
      final snapshot = await _contacts
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('priority', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmergencyContact.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch contacts by type: $e');
    }
  }

  // Admin functions
  static Future<String> createContact(EmergencyContact contact) async {
    try {
      final docRef = await _contacts.add(contact.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  static Future<void> updateContact(String id, EmergencyContact contact) async {
    try {
      await _contacts.doc(id).update(contact.toJson());
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  static Future<void> deleteContact(String id) async {
    try {
      await _contacts.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  static Future<List<EmergencyContact>> getAllContacts() async {
    try {
      final snapshot = await _contacts.get();
      
      final contacts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmergencyContact.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
      
      // Sort manually to avoid index requirements
      contacts.sort((a, b) {
        final countryCompare = a.country.compareTo(b.country);
        if (countryCompare != 0) return countryCompare;
        return b.priority.compareTo(a.priority);
      });
      
      return contacts;
    } catch (e) {
      print('Error fetching contacts: $e');
      throw Exception('Failed to fetch all contacts: $e');
    }
  }

  // Seed default data
  static Future<void> seedDefaultData() async {
    try {
      final snapshot = await _contacts.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Emergency contacts already exist, skipping seeding');
        return; // Data already exists
      }
      
      print('Seeding default emergency contacts...');
      final defaultContacts = _getAllDefaultContacts();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final contact in defaultContacts) {
        final docRef = _contacts.doc(contact.id);
        batch.set(docRef, contact.toJson());
      }
      
      await batch.commit();
      print('Successfully seeded ${defaultContacts.length} emergency contacts');
    } catch (e) {
      print('Failed to seed emergency contacts: $e');
      // Try to add contacts individually as fallback
      try {
        final defaultContacts = _getAllDefaultContacts();
        for (final contact in defaultContacts) {
          await _contacts.doc(contact.id).set(contact.toJson());
        }
        print('Fallback seeding completed');
      } catch (e2) {
        print('Fallback seeding also failed: $e2');
        rethrow;
      }
    }
  }

  // Default data for offline/fallback
  static List<EmergencyContact> _getDefaultContactsForCountry(String country) {
    final allContacts = _getAllDefaultContacts();
    return allContacts.where((contact) => contact.country == country).toList();
  }

  static List<EmergencyContact> _getAllDefaultContacts() {
    return [
      // Nigeria
      EmergencyContact(
        id: 'ng-npf-cyber',
        type: ContactType.cyberCrime,
        name: 'Nigeria Police Force Cybercrime Unit',
        department: 'NPF-SCID Cybercrime Division',
        phone: '+234-1-4931260',
        email: 'cybercrime@npf.gov.ng',
        website: 'https://www.npf.gov.ng',
        address: 'Louis Edet House, Area 11, Garki, Abuja',
        description: 'Primary cybercrime reporting unit for Nigeria',
        availability: '24/7 Emergency Hotline',
        languages: ['English', 'Hausa', 'Yoruba', 'Igbo'],
        country: 'Nigeria',
        priority: 10,
      ),
      EmergencyContact(
        id: 'ng-efcc',
        type: ContactType.cyberCrime,
        name: 'Economic and Financial Crimes Commission',
        department: 'EFCC Cybercrime Division',
        phone: '+234-9-9044751',
        email: 'info@efcc.gov.ng',
        website: 'https://www.efcc.gov.ng',
        address: 'Plot 802/803 Ralph Shodeinde Street, CBD, Abuja',
        description: 'Financial crimes and advanced fee fraud',
        availability: 'Mon-Fri 8AM-6PM',
        languages: ['English'],
        country: 'Nigeria',
        priority: 9,
      ),
      EmergencyContact(
        id: 'ng-police-emergency',
        type: ContactType.police,
        name: 'Nigeria Police Emergency',
        department: 'Emergency Response Unit',
        phone: '199',
        emergencyNumber: '199',
        email: 'emergency@npf.gov.ng',
        description: 'General police emergency services',
        availability: '24/7',
        languages: ['English', 'Local languages'],
        country: 'Nigeria',
        priority: 8,
      ),
      
      // Kenya
      EmergencyContact(
        id: 'ke-dci-cyber',
        type: ContactType.cyberCrime,
        name: 'Kenya Police Cybercrime Unit',
        department: 'Directorate of Criminal Investigations',
        phone: '+254-20-2240000',
        email: 'cybercrime@dci.go.ke',
        website: 'https://www.dci.go.ke',
        address: 'Kiambu Road, Nairobi',
        description: 'Kenya\'s primary cybercrime investigation unit',
        availability: '24/7 Hotline',
        languages: ['English', 'Swahili'],
        country: 'Kenya',
        priority: 10,
      ),
      EmergencyContact(
        id: 'ke-ca',
        type: ContactType.cyberCrime,
        name: 'Communications Authority of Kenya',
        department: 'Consumer Affairs',
        phone: '+254-20-4242000',
        email: 'info@ca.go.ke',
        website: 'https://www.ca.go.ke',
        address: 'Waiyaki Way, Nairobi',
        description: 'Telecommunications and online fraud reporting',
        availability: 'Mon-Fri 8AM-5PM',
        languages: ['English', 'Swahili'],
        country: 'Kenya',
        priority: 8,
      ),
      EmergencyContact(
        id: 'ke-police-emergency',
        type: ContactType.police,
        name: 'Kenya Police Emergency',
        department: 'Emergency Services',
        phone: '999',
        emergencyNumber: '999',
        description: 'General emergency services',
        availability: '24/7',
        languages: ['English', 'Swahili'],
        country: 'Kenya',
        priority: 7,
      ),
      
      // South Africa
      EmergencyContact(
        id: 'za-hawks-cyber',
        type: ContactType.cyberCrime,
        name: 'Hawks Cybercrime Unit',
        department: 'Directorate for Priority Crime Investigation',
        phone: '+27-12-845-6000',
        email: 'info@saps.gov.za',
        website: 'https://www.saps.gov.za',
        address: '230 Pretorius Street, Pretoria',
        description: 'Specialized cybercrime investigation unit',
        availability: '24/7 Hotline',
        languages: ['English', 'Afrikaans', 'Zulu', 'Xhosa'],
        country: 'South Africa',
        priority: 10,
      ),
      EmergencyContact(
        id: 'za-police-emergency',
        type: ContactType.police,
        name: 'South African Police Service',
        department: 'Emergency Services',
        phone: '10111',
        emergencyNumber: '10111',
        description: 'General police emergency services',
        availability: '24/7',
        languages: ['English', 'Afrikaans', 'Local languages'],
        country: 'South Africa',
        priority: 8,
      ),

      // Ghana
      EmergencyContact(
        id: 'gh-csa',
        type: ContactType.cyberCrime,
        name: 'Cyber Security Authority (CSA)',
        department: 'CERT-GH Cybercrime Incident Reporting',
        phone: '292',
        email: 'report@csa.gov.gh',
        website: 'https://www.csa.gov.gh',
        description: 'National 24/7 cybercrime & incident reporting point of contact (call/SMS 292, WhatsApp 0501603111)',
        availability: '24/7',
        languages: ['English'],
        country: 'Ghana',
        priority: 10,
      ),

      // Kenya extra already above; add others below

      // Uganda
      EmergencyContact(
        id: 'ug-upf-cid',
        type: ContactType.cyberCrime,
        name: 'Uganda Police Force',
        department: 'Criminal Investigations Directorate — Cyber Crime',
        phone: '+256-414-233814',
        email: 'info@upf.go.ug',
        website: 'https://upf.go.ug',
        description: 'Report cyber and financial crime via the Police CID',
        availability: 'Mon-Fri',
        languages: ['English'],
        country: 'Uganda',
        priority: 10,
      ),

      // Rwanda
      EmergencyContact(
        id: 'rw-rib',
        type: ContactType.cyberCrime,
        name: 'Rwanda Investigation Bureau (RIB)',
        department: 'Cybercrime Unit',
        phone: '166',
        website: 'https://www.rib.gov.rw',
        description: 'Toll-free hotline 166 to report cybercrime',
        availability: '24/7 hotline',
        languages: ['Kinyarwanda', 'English', 'French'],
        country: 'Rwanda',
        priority: 10,
      ),

      // Cameroon
      EmergencyContact(
        id: 'cm-antic',
        type: ContactType.cyberCrime,
        name: 'ANTIC — National CIRT',
        department: 'Computer Incident Response Team',
        phone: '+237-242-099-164',
        website: 'https://www.antic.cm',
        description: "Cameroon's national cyber incident response team",
        availability: 'Mon-Fri',
        languages: ['French', 'English'],
        country: 'Cameroon',
        priority: 10,
      ),

      // Senegal
      EmergencyContact(
        id: 'sn-dgpn-cyber',
        type: ContactType.cyberCrime,
        name: 'Police Nationale — Cybercriminalité',
        department: 'Division spéciale de lutte contre la cybercriminalité',
        phone: '',
        website: 'https://signalementcyber.dgpn.sn',
        description: 'Plateforme nationale de signalement de la cybercriminalité',
        availability: '24/7 online',
        languages: ['French'],
        country: 'Senegal',
        priority: 10,
      ),

      // Tanzania
      EmergencyContact(
        id: 'tz-police-cyber',
        type: ContactType.cyberCrime,
        name: 'Tanzania Police Force — Cyber Crime Unit',
        department: 'Report via Police; TCRA regulates communications',
        phone: '',
        website: 'https://www.tcra.go.tz',
        description: 'Report cybercrime to the Police Cyber Crime Unit',
        availability: 'Mon-Fri',
        languages: ['Swahili', 'English'],
        country: 'Tanzania',
        priority: 10,
      ),

      // Egypt
      EmergencyContact(
        id: 'eg-moi-cyber',
        type: ContactType.cyberCrime,
        name: 'Anti-Cyber Crime Department (Ministry of Interior)',
        department: 'Internet Investigations Unit',
        phone: '108',
        description: 'Cybercrime hotline 108; or report at the nearest police station',
        availability: '24/7 hotline',
        languages: ['Arabic', 'English'],
        country: 'Egypt',
        priority: 10,
      ),

      // Tunisia
      EmergencyContact(
        id: 'tn-tuncert',
        type: ContactType.cyberCrime,
        name: 'tunCERT (ANSI / ANCS)',
        department: 'National Computer Emergency Response Team',
        phone: '+216-71-843200',
        email: 'incident@ansi.tn',
        website: 'https://tuncert.ansi.tn',
        description: "Tunisia's national CERT — 24/7 incident hotline",
        availability: '24/7',
        languages: ['Arabic', 'French', 'English'],
        country: 'Tunisia',
        priority: 10,
      ),

      // Morocco
      EmergencyContact(
        id: 'ma-dgsn-eblagh',
        type: ContactType.cyberCrime,
        name: 'DGSN — E-Blagh',
        department: 'Online cybercrime reporting platform',
        phone: '',
        description: 'Report online via the DGSN "E-Blagh" platform, or at the nearest police station',
        availability: '24/7 online',
        languages: ['Arabic', 'French'],
        country: 'Morocco',
        priority: 10,
      ),

      // Ethiopia
      EmergencyContact(
        id: 'et-insa',
        type: ContactType.cyberCrime,
        name: 'Information Network Security Agency (INSA)',
        department: 'Cyber Incident Reporting',
        phone: '',
        description: 'Report cyber incidents to INSA, or the nearest Federal Police station',
        availability: 'Mon-Fri',
        languages: ['Amharic', 'English'],
        country: 'Ethiopia',
        priority: 10,
      ),

      // Algeria
      EmergencyContact(
        id: 'dz-dgsn-cyber',
        type: ContactType.cyberCrime,
        name: 'DGSN — Cybercrime Brigades',
        department: 'Brigades de lutte contre la cybercriminalité',
        phone: '',
        description: 'Report to the DGSN cybercrime brigades or the nearest police station',
        availability: 'Mon-Fri',
        languages: ['Arabic', 'French'],
        country: 'Algeria',
        priority: 10,
      ),
    ];
  }
}

// Emergency contact model
class EmergencyContact {
  final String id;
  final ContactType type;
  final String name;
  final String department;
  final String phone;
  final String? emergencyNumber;
  final String? email;
  final String? website;
  final String? address;
  final String description;
  final String availability;
  final List<String> languages;
  final String country;
  final int priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmergencyContact({
    required this.id,
    required this.type,
    required this.name,
    required this.department,
    required this.phone,
    this.emergencyNumber,
    this.email,
    this.website,
    this.address,
    required this.description,
    required this.availability,
    required this.languages,
    required this.country,
    required this.priority,
    this.createdAt,
    this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      type: ContactType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ContactType.police,
      ),
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      phone: json['phone'] ?? '',
      emergencyNumber: json['emergency_number'],
      email: json['email'],
      website: json['website'],
      address: json['address'],
      description: json['description'] ?? '',
      availability: json['availability'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      country: json['country'] ?? '',
      priority: json['priority'] ?? 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'name': name,
      'department': department,
      'phone': phone,
      'emergency_number': emergencyNumber,
      'email': email,
      'website': website,
      'address': address,
      'description': description,
      'availability': availability,
      'languages': languages,
      'country': country,
      'priority': priority,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Helper methods
  Color get typeColor {
    switch (type) {
      case ContactType.cyberCrime:
        return Colors.red.shade600;
      case ContactType.police:
        return Colors.blue.shade600;
      case ContactType.financial:
        return Colors.green.shade600;
      case ContactType.telecom:
        return Colors.purple.shade600;
      case ContactType.legal:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case ContactType.cyberCrime:
        return Icons.security;
      case ContactType.police:
        return Icons.local_police;
      case ContactType.financial:
        return Icons.account_balance;
      case ContactType.telecom:
        return Icons.phone;
      case ContactType.legal:
        return Icons.gavel;
      default:
        return Icons.contact_phone;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case ContactType.cyberCrime:
        return 'Cybercrime Unit';
      case ContactType.police:
        return 'Police Emergency';
      case ContactType.financial:
        return 'Financial Crime';
      case ContactType.telecom:
        return 'Telecom Authority';
      case ContactType.legal:
        return 'Legal Aid';
      default:
        return 'General Contact';
    }
  }
}

enum ContactType {
  cyberCrime,
  police,
  financial,
  telecom,
  legal,
}

extension ContactTypeExtension on ContactType {
  String get displayName {
    switch (this) {
      case ContactType.cyberCrime:
        return 'Cybercrime';
      case ContactType.police:
        return 'Police';
      case ContactType.financial:
        return 'Financial';
      case ContactType.telecom:
        return 'Telecom';
      case ContactType.legal:
        return 'Legal';
    }
  }
}