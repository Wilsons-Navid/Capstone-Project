import 'dart:convert';
import 'dart:io';

const translationsDir = 'assets/translations';

// Key set we rely on in the UI (dashboard, drawer, language page)
final requiredKeys = <String>{
  // Common / language page
  'common.current_language',
  'common.apply_changes',
  'common.language_changed',
  'common.close',
  'common.current',
  'language.settings',
  'language.choose_preferred',
  // Drawer / nav
  'nav.dashboard',
  'nav.report',
  'nav.cases',
  'nav.profile',
  'nav.scanner',
  'nav.education',
  'nav.emergency',
  'nav.language',
  'nav.help',
  'nav.about',
  'nav.signout',
  // Dashboard hero/sections
  'dashboard.welcome',
  'dashboard.greeting',
  'dashboard.subtitle',
  'dashboard.features_title',
  'dashboard.recent_activity',
  // Dashboard features (titles/subtitles)
  'incidents.report_incident',
  'dashboard.secure_reporting',
  'ai.assistant_name',
  'dashboard.ai_analysis',
  'cases.track_cases',
  'dashboard.monitor_reports',
  'scanner.threat_scanner',
  'dashboard.scan_content',
  'education.learn_protect',
  'education.security_education',
  'emergency.immediate_help',
};

void main() async {
  final baseFile = File('$translationsDir/en.json');
  if (!await baseFile.exists()) {
    stderr.writeln('Missing $translationsDir/en.json');
    exit(2);
  }

  final base = json.decode(await baseFile.readAsString()) as Map<String, dynamic>;
  final flatBase = _flatten(base);

  // If requiredKeys contains something not in base, warn
  final missingInBase = requiredKeys.where((k) => !flatBase.containsKey(k)).toList();
  if (missingInBase.isNotEmpty) {
    stdout.writeln('[warn] Required keys not in en.json: ${missingInBase.join(', ')}');
  }

  final dir = Directory(translationsDir);
  final files = await dir.list().where((e) => e is File && e.path.endsWith('.json')).cast<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final lang = f.uri.pathSegments.last.replaceAll('.json', '');
    final data = json.decode(await f.readAsString()) as Map<String, dynamic>;
    final flat = _flatten(data);
    final missing = requiredKeys.where((k) => !flat.containsKey(k) || (flat[k] ?? '').toString().trim().isEmpty).toList();
    stdout.writeln('[$lang] missing: ${missing.isEmpty ? 'none' : missing.length}');
    if (missing.isNotEmpty) {
      for (final m in missing) {
        stdout.writeln('  - $m');
      }
    }
  }
}

Map<String, String> _flatten(Map<String, dynamic> obj, [String prefix = '']) {
  final out = <String, String>{};
  obj.forEach((k, v) {
    final key = prefix.isEmpty ? k : '$prefix.$k';
    if (v is Map<String, dynamic>) {
      out.addAll(_flatten(v, key));
    } else if (v is List) {
      out[key] = v.join(', ');
    } else if (v != null) {
      out[key] = v.toString();
    }
  });
  return out;
}

