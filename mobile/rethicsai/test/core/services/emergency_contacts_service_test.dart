import 'package:flutter_test/flutter_test.dart';
import 'package:rethicssec/core/services/emergency_contacts_service.dart';

/// Unit tests for the bundled authority-contacts data that powers the
/// "Report to authorities" feature. These run without Firebase — they verify
/// the offline/default dataset directly.
void main() {
  group('EmergencyContactsService.supportedCountries', () {
    test('includes the core African countries', () {
      final countries = EmergencyContactsService.supportedCountries();
      for (final c in [
        'Nigeria',
        'Kenya',
        'South Africa',
        'Ghana',
        'Uganda',
        'Rwanda',
      ]) {
        expect(countries, contains(c), reason: '$c should be bundled');
      }
    });

    test('covers at least 14 countries and is sorted and unique', () {
      final countries = EmergencyContactsService.supportedCountries();
      expect(countries.length, greaterThanOrEqualTo(14));

      final sorted = [...countries]..sort();
      expect(countries, equals(sorted), reason: 'should be alphabetically sorted');
      expect(countries.toSet().length, equals(countries.length),
          reason: 'should contain no duplicates');
    });
  });

  group('EmergencyContact model', () {
    test('round-trips through JSON', () {
      final contact = EmergencyContact(
        id: 'tt-test',
        type: ContactType.cyberCrime,
        name: 'Test Cyber Unit',
        department: 'Cyber Division',
        phone: '+100000000',
        description: 'A test contact',
        availability: '24/7',
        languages: ['English', 'French'],
        country: 'Testland',
        priority: 9,
      );

      final restored = EmergencyContact.fromJson({
        ...contact.toJson(),
        'id': contact.id,
      });

      expect(restored.name, equals(contact.name));
      expect(restored.country, equals(contact.country));
      expect(restored.type, equals(ContactType.cyberCrime));
      expect(restored.languages, containsAll(['English', 'French']));
      expect(restored.priority, equals(9));
    });
  });
}
