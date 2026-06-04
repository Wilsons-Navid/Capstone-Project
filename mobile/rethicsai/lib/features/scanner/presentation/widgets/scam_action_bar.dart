import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/themes/app_theme.dart';

/// Action layer for a scan result: pulls phone numbers, emails and links out of
/// the scanned text and lets the user act on them — call, send a message, or
/// email — with a pre-filled "what to say" placeholder. Also offers a generic
/// report action. Renders nothing when no contact is found.
///
/// (Tier-1 action-enabling UX: turns a verdict into something the user can do.)
class ScamActionBar extends StatelessWidget {
  final String content;
  final bool isThreat;

  const ScamActionBar({super.key, required this.content, this.isThreat = true});

  // Pre-filled bodies the user can edit before sending.
  static const _verifyTemplate =
      'Hello, I received this message and want to verify whether it is genuine '
      'before taking any action. Can you confirm?';
  static const _reportTemplate =
      'I want to report a suspected scam. I received the following message:\n\n';

  static final _phoneRe = RegExp(r'(?<!\d)(\+?\d[\d\s\-()]{6,}\d)');
  static final _emailRe =
      RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');

  List<String> _phones() => _phoneRe
      .allMatches(content)
      .map((m) => m.group(0)!.replaceAll(RegExp(r'[\s\-()]'), '').trim())
      .where((p) => p.replaceAll('+', '').length >= 7)
      .toSet()
      .toList();

  List<String> _emails() =>
      _emailRe.allMatches(content).map((m) => m.group(0)!).toSet().toList();

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${uri.scheme}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app available for this action')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phones = _phones();
    final emails = _emails();
    if (phones.isEmpty && emails.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Take action',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (isThreat) ...[
            const SizedBox(height: 4),
            Text(
              'Be careful — verify before you call or reply. Messages open pre-filled so you can edit them.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 10),
          for (final phone in phones) _contactRow(context, icon: Icons.phone, label: phone, actions: [
            _ActionChip('Call', Icons.call, () => _launch(context, Uri(scheme: 'tel', path: phone))),
            _ActionChip('Message', Icons.sms, () => _launch(
                  context,
                  Uri(scheme: 'sms', path: phone, queryParameters: {'body': _verifyTemplate}),
                )),
          ]),
          for (final email in emails) _contactRow(context, icon: Icons.email, label: email, actions: [
            _ActionChip('Email', Icons.mail_outline, () => _launch(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: email,
                    queryParameters: {'subject': 'Verifying a suspicious message', 'body': _verifyTemplate},
                  ),
                )),
          ]),
          const Divider(height: 20),
          // Generic report — opens an email draft pre-filled with the message.
          _ActionChip('Report this scam', Icons.flag_outlined, () => _launch(
                context,
                Uri(
                  scheme: 'mailto',
                  path: '',
                  queryParameters: {
                    'subject': 'Scam report',
                    'body': '$_reportTemplate$content',
                  },
                ),
              )).build(context, filled: true),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context,
      {required IconData icon, required String label, required List<_ActionChip> actions}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          ...actions.map((a) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: a.build(context),
              )),
        ],
      ),
    );
  }
}

class _ActionChip {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _ActionChip(this.label, this.icon, this.onTap);

  Widget build(BuildContext context, {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
