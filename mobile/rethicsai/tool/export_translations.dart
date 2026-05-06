import 'dart:convert';
import 'dart:io';

const translationsDir = 'assets/translations';

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final outPath = opts['out'] ?? 'translations_export.csv';
  final includeBom = (opts['bom'] ?? 'true').toLowerCase() == 'true';

  final dir = Directory(translationsDir);
  if (!await dir.exists()) {
    stderr.writeln('Missing $translationsDir');
    exit(2);
  }

  final files = await dir
      .list()
      .where((e) => e is File && e.path.endsWith('.json'))
      .cast<File>()
      .toList();
  if (files.isEmpty) {
    stderr.writeln('No JSON files in $translationsDir');
    exit(2);
  }

  // Determine languages
  final langs = files
      .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
      .toSet()
      .toList();
  langs.sort();
  if (langs.remove('en')) langs.insert(0, 'en');

  // Build union of keys across all locales
  final Map<String, Map<String, String>> byLang = {};
  final Set<String> allKeys = {};
  for (final lang in langs) {
    final path = '$translationsDir/$lang.json';
    final f = File(path);
    if (!await f.exists()) continue;
    final data = json.decode(await f.readAsString()) as Map<String, dynamic>;
    final flat = _flatten(data);
    byLang[lang] = flat;
    allKeys.addAll(flat.keys);
  }

  final sortedKeys = allKeys.toList()..sort();

  // Write CSV
  final sink = File(outPath).openWrite();
  if (includeBom) {
    // UTF-8 BOM for Excel compatibility on Windows
    sink.add([0xEF, 0xBB, 0xBF]);
  }
  // Header
  sink.writeln(_csvRow(['key', ...langs]));
  for (final key in sortedKeys) {
    final row = <String>[key];
    for (final lang in langs) {
      final v = byLang[lang]?[key] ?? '';
      row.add(v);
    }
    sink.writeln(_csvRow(row));
  }
  await sink.flush();
  await sink.close();
  stdout.writeln('Wrote $outPath with ${sortedKeys.length} keys and ${langs.length} languages.');
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

String _csvRow(List<String> cols) {
  return cols.map(_csvEscape).join(',');
}

String _csvEscape(String input) {
  var s = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final needsQuotes = s.contains(',') || s.contains('"') || s.contains('\n');
  s = s.replaceAll('"', '""');
  return needsQuotes ? '"$s"' : s;
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (final a in args) {
    if (a.startsWith('--')) {
      final idx = a.indexOf('=');
      if (idx > 2) {
        out[a.substring(2, idx)] = a.substring(idx + 1);
      } else {
        out[a.substring(2)] = 'true';
      }
    }
  }
  return out;
}

