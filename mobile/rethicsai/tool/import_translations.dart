import 'dart:convert';
import 'dart:io';

const translationsDir = 'assets/translations';

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final inPath = opts['in'] ?? 'translations_export.csv';
  final dryRun = (opts['dry-run'] ?? 'false').toLowerCase() == 'true';
  final langsFilter = (opts['langs'] ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();

  final file = File(inPath);
  if (!await file.exists()) {
    stderr.writeln('Input CSV not found: $inPath');
    exit(2);
  }
  final bytes = await file.readAsBytes();
  var text = utf8.decode(bytes, allowMalformed: true);
  // Strip UTF-8 BOM if present
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }

  final records = _parseCsv(text);
  if (records.isEmpty) {
    stderr.writeln('Empty CSV: $inPath');
    exit(2);
  }

  final header = records.first;
  if (header.isEmpty || header[0].toLowerCase() != 'key') {
    stderr.writeln('CSV header must start with "key"');
    exit(2);
  }

  final langs = <String>[];
  for (var i = 1; i < header.length; i++) {
    final lang = header[i].trim();
    if (lang.isEmpty) continue;
    if (langsFilter.isEmpty || langsFilter.contains(lang)) {
      langs.add(lang);
    }
  }
  if (langs.isEmpty) {
    stderr.writeln('No languages to import (check --langs or header)');
    exit(2);
  }

  // Prepare per-language maps of key->value
  final Map<String, Map<String, String>> updates = {
    for (final lang in langs) lang: <String, String>{}
  };

  for (var r = 1; r < records.length; r++) {
    final row = records[r];
    if (row.isEmpty) continue;
    final key = row[0].trim();
    if (key.isEmpty) continue;
    for (var ci = 1; ci < header.length && ci < row.length; ci++) {
      final lang = header[ci].trim();
      if (!langs.contains(lang)) continue;
      final value = row[ci];
      // Only update when non-empty; keep existing if empty
      if (value.trim().isNotEmpty) {
        updates[lang]![key] = value;
      }
    }
  }

  // Apply updates to each language JSON
  for (final lang in langs) {
    final targetPath = '$translationsDir/$lang.json';
    final targetFile = File(targetPath);
    Map<String, dynamic> jsonObj = {};
    if (await targetFile.exists()) {
      try {
        jsonObj = json.decode(await targetFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        stderr.writeln('warn: failed to parse $targetPath, starting fresh');
        jsonObj = {};
      }
    }

    final kv = updates[lang]!;
    var applied = 0;
    kv.forEach((k, v) {
      _setPath(jsonObj, k.split('.'), v);
      applied++;
    });

    if (dryRun) {
      stdout.writeln('[dry-run] $lang: would update $applied strings in $targetPath');
    } else {
      await targetFile.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonObj) + '\n');
      stdout.writeln('[write] $lang: updated $applied strings in $targetPath');
    }
  }
}

void _setPath(Map<String, dynamic> root, List<String> parts, String value) {
  Map<String, dynamic> curr = root;
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    if (i == parts.length - 1) {
      curr[p] = value;
    } else {
      final next = curr[p];
      if (next is Map<String, dynamic>) {
        curr = next;
      } else {
        final m = <String, dynamic>{};
        curr[p] = m;
        curr = m;
      }
    }
  }
}

List<List<String>> _parseCsv(String input) {
  final records = <List<String>>[];
  final field = StringBuffer();
  final row = <String>[];
  var i = 0;
  final n = input.length;
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    // ignore empty trailing rows
    if (row.isNotEmpty) records.add(List<String>.from(row));
    row.clear();
  }

  while (i < n) {
    final ch = input[i];
    if (inQuotes) {
      if (ch == '"') {
        // peek next
        if (i + 1 < n && input[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        } else {
          inQuotes = false;
          i++;
          continue;
        }
      } else {
        field.write(ch);
        i++;
        continue;
      }
    } else {
      if (ch == '"') {
        inQuotes = true;
        i++;
        continue;
      }
      if (ch == ',') {
        endField();
        i++;
        continue;
      }
      if (ch == '\r') {
        endField();
        // consume optional \n
        if (i + 1 < n && input[i + 1] == '\n') i++;
        i++;
        endRow();
        continue;
      }
      if (ch == '\n') {
        endField();
        i++;
        endRow();
        continue;
      }
      field.write(ch);
      i++;
    }
  }
  // flush last field/row
  endField();
  endRow();
  return records;
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

