import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/emergency_contacts_service.dart';

/// "Report to authorities" card shown after a scam scan. Has a country dropdown
/// (defaults to the user's profile country) so the user can pick which country's
/// cyber-crime / police authority to contact — each with Call / Email / Report-online
/// actions and a pre-filled scam report.
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
  List<String> _countries = [];
  String? _country;
  Future<List<EmergencyContact>>? _future;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  /// Load the selectable countries from Firestore (falls back to bundled
  /// defaults inside the service), then default to the user's profile country
  /// when it's available, otherwise Nigeria, otherwise the first country.
  Future<void> _loadCountries() async {
    final countries = await EmergencyContactsService.getAvailableCountries();
    final profile = await _profileCountry();
    if (!mounted) return;

    String? initial;
    if (profile != null && countries.contains(profile)) {
      initial = profile;
    } else if (countries.contains('Nigeria')) {
      initial = 'Nigeria';
    } else if (countries.isNotEmpty) {
      initial = countries.first;
    }

    setState(() {
      _countries = countries;
      _country = initial;
      _loading = false;
      _future = initial != null
          ? EmergencyContactsService.getContactsByCountry(initial)
          : null;
    });
  }

  /// The signed-in user's profile country, if any.
  Future<String?> _profileCountry() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['country'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _selectCountry(String? c) {
    if (c == null || c == _country) return;
    setState(() {
      _country = c;
      _future = EmergencyContactsService.getContactsByCountry(c);
    });
  }

  String get _reportBody {
    final c = widget.category;
    const known = {'advance_fee_fraud', 'mobile_money_fraud', 'phishing', 'not_a_scam'};
    if (c != null && known.contains(c)) {
      return 'scanner.report_intro'
              .tr(namedArgs: {'category': 'scanner.cat_$c'.tr()}) +
          widget.content;
    }
    return 'scanner.report_template'.tr() + widget.content;
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isThreat) return const SizedBox.shrink();
    final amber = AppTheme.secondaryDark;

    // While countries are loading, show the card shell with a spinner so it
    // doesn't pop in late.
    if (_loading) {
      return _shell(
        amber,
        child: Row(
          children: [
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading authority contacts…',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_country == null) return const SizedBox.shrink();

    return _shell(
      amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.4)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _country,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: amber),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: _countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _selectCountry,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<EmergencyContact>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final contacts = (snapshot.data ?? [])
                  .where((c) => c.type == ContactType.cyberCrime ||
                      c.type == ContactType.financial ||
                      c.type == ContactType.police)
                  .take(3)
                  .toList();
              if (contacts.isEmpty) {
                return Text(
                  'No authority contact on file for this country yet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: contacts.map(_authorityRow).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Shared card chrome (background + "Report to authorities" header) wrapping
  /// either the loading spinner or the loaded picker + contacts.
  Widget _shell(Color amber, {required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, size: 18, color: amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'scanner.report_to_authorities'.tr(),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _authorityRow(EmergencyContact c) {
    final hasPhone = c.phone.isNotEmpty;
    final hasEmail = (c.email ?? '').isNotEmpty;
    final hasSite = (c.website ?? '').isNotEmpty;
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
          if (hasPhone || hasEmail || hasSite)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasPhone)
                  _btn('scanner.call'.tr(), Icons.call,
                      () => _launch(Uri(scheme: 'tel', path: c.phone))),
                if (hasEmail)
                  _btn('scanner.email_report'.tr(), Icons.mail_outline, () => _launch(Uri(
                        scheme: 'mailto',
                        path: c.email,
                        queryParameters: {
                          'subject': 'scanner.report_subject'.tr(),
                          'body': _reportBody,
                        },
                      ))),
                if (hasSite)
                  _btn('scanner.report_online'.tr(), Icons.open_in_new,
                      () => _launch(Uri.parse(c.website!))),
              ],
            )
          else
            // No actionable contact — show guidance text instead.
            Text(c.description,
                style: TextStyle(fontSize: 11, color: Colors.grey[700])),
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
          color: AppTheme.secondaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.secondaryDark),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryDark)),
          ],
        ),
      ),
    );
  }
}
