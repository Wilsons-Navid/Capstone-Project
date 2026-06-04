import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';

/// Shows the verdict from the project's scam-classifier ensemble model
/// (the `details['ai_model']` payload a [ScanResult] carries after a text scan).
///
/// Pass `result.details?['ai_model']`; renders nothing when the model did not run
/// (e.g. API unconfigured/unreachable), so the scanner degrades gracefully.
class AiModelVerdictCard extends StatelessWidget {
  final Map<String, dynamic>? aiModel;

  const AiModelVerdictCard({super.key, required this.aiModel});

  String _cat(String c) {
    const known = {'advance_fee_fraud', 'mobile_money_fraud', 'phishing', 'not_a_scam'};
    return known.contains(c) ? 'scanner.cat_$c'.tr() : c;
  }

  @override
  Widget build(BuildContext context) {
    final data = aiModel;
    if (data == null) return const SizedBox.shrink();

    final category = data['category']?.toString() ?? 'unknown';
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0;
    final isSafe = category == 'not_a_scam';
    final accent = isSafe ? Colors.green[700]! : Colors.red[700]!;

    final scoresRaw = (data['scores'] as Map?) ?? const {};
    final scores = scoresRaw.entries
        .map((e) => MapEntry(e.key.toString(), (e.value as num).toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                'scanner.ai_verdict_title'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const Spacer(),
              Text(
                '${(confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _cat(category),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          // Per-class probabilities as slim bars.
          ...scores.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        _cat(e.key),
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value.clamp(0.0, 1.0).toDouble(),
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          color: e.key == category ? accent : Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${(e.value * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
          Text(
            'scanner.ai_ensemble_caption'.tr(),
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: AppTheme.primaryColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
