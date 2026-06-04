import 'package:easy_localization/easy_localization.dart';
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
          SnackBar(content: Text('scanner.no_app_available'.tr())),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scanner.no_app_available'.tr())),
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
                'scanner.take_action'.tr(),
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
              'scanner.action_caution'.tr(),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 10),
          for (final phone in phones) _contactRow(context, icon: Icons.phone, label: phone, actions: [
            _ActionChip('scanner.call'.tr(), Icons.call,
                () => _launch(context, Uri(scheme: 'tel', path: phone))),
            _ActionChip('scanner.message'.tr(), Icons.sms, () => _launch(
                  context,
                  Uri(scheme: 'sms', path: phone, queryParameters: {'body': 'scanner.verify_template'.tr()}),
                )),
          ]),
          for (final email in emails) _contactRow(context, icon: Icons.email, label: email, actions: [
            _ActionChip('scanner.email'.tr(), Icons.mail_outline, () => _launch(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: email,
                    queryParameters: {
                      'subject': 'scanner.verify_subject'.tr(),
                      'body': 'scanner.verify_template'.tr(),
                    },
                  ),
                )),
          ]),
          const Divider(height: 20),
          // Generic report — opens an email draft pre-filled with the message.
          _ActionChip('scanner.report_scam'.tr(), Icons.flag_outlined, () => _launch(
                context,
                Uri(
                  scheme: 'mailto',
                  path: '',
                  queryParameters: {
                    'subject': 'scanner.report_subject'.tr(),
                    'body': '${'scanner.report_template'.tr()}$content',
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
