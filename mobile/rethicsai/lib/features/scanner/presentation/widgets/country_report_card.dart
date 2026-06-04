import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/emergency_contacts_service.dart';

/// Country-aware "report to the authorities" card. Looks up the signed-in user's
/// country, finds its cyber-crime / police contacts, and offers to call or email
/// them with a pre-filled report of the scanned scam.
///
/// Renders nothing for a safe result, or when no authority contact is found.
class CountryReportCard extends StatefulWidget {
  final String content;
  final String? category;
  final bool isThreat;

  const CountryReportCard({
    super.key,
    required this.content,
    this.category,
    this.isThreat = true,
  });

  @override
  State<CountryReportCard> createState() => _CountryReportCardState();
}

class _CountryReportCardState extends State<CountryReportCard> {
  late final Future<List<EmergencyContact>> _future;

  static const _readable = {
    'advance_fee_fraud': 'advance-fee fraud',
    'mobile_money_fraud': 'mobile-money fraud',
    'phishing': 'phishing',
    'not_a_scam': 'not a scam',
  };

  @override
  void initState() {
    super.initState();
    _future = _loadAuthorities();
  }

  Future<List<EmergencyContact>> _loadAuthorities() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final country = doc.data()?['country'] as String?;
      if (country == null || country.isEmpty) return [];

      final contacts =
          await EmergencyContactsService.getContactsByCountry(country);
      final cyber = contacts
          .where((c) => c.type == ContactType.cyberCrime)
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      final police =
          contacts.where((c) => c.type == ContactType.police).toList();
      return (cyber.isNotEmpty ? cyber : police).take(2).toList();
    } catch (_) {
      return [];
    }
  }

  String get _reportBody {
    final cat = _readable[widget.category] ?? 'a scam';
    return 'I want to report a suspected $cat. I received the following message:'
        '\n\n${widget.content}';
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isThreat) return const SizedBox.shrink();

    return FutureBuilder<List<EmergencyContact>>(
      future: _future,
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? [];
        if (contacts.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance, size: 18, color: Colors.orange[800]),
                  const SizedBox(width: 6),
                  Text(
                    'Report to authorities',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final c in contacts) _authorityRow(c),
            ],
          ),
        );
      },
    );
  }

  Widget _authorityRow(EmergencyContact c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (c.department.isNotEmpty)
            Text(c.department,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Row(
            children: [
              if (c.phone.isNotEmpty)
                _btn('Call', Icons.call,
                    () => _launch(Uri(scheme: 'tel', path: c.phone))),
              if (c.email.isNotEmpty) ...[
                const SizedBox(width: 8),
                _btn('Email report', Icons.mail_outline, () => _launch(Uri(
                      scheme: 'mailto',
                      path: c.email,
                      queryParameters: {
                        'subject': 'Scam report',
                        'body': _reportBody,
                      },
                    ))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.orange[900]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[900])),
          ],
        ),
      ),
    );
  }
}
