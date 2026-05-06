// A CLI tool to generate or fill missing translations using an external API
// Usage examples:
//   dart run tool/translate_assets.dart --provider=google --api-key=$GOOGLE_API_KEY --to=fr,ar,ha,yo,ig,zu,xh,af,sw
//   dart run tool/translate_assets.dart --provider=azure --api-key=$AZURE_KEY --region=$AZURE_REGION --to=fr,ar
// Notes:
// - Douala (dua) is not supported by most providers; keep it manual.
// - The tool merges into assets/translations/<lang>.json and only fills missing keys.

import 'dart:convert';
import 'dart:io';

const translationsDir = 'assets/translations';

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final provider = (opts['provider'] ?? 'libre').toLowerCase();
  final apiKey = opts['api-key'] ?? Platform.environment['TRANSLATE_API_KEY'];
  final region = opts['region'] ?? Platform.environment['TRANSLATE_REGION'];
  final libreUrl = opts['libre-url'] ?? Platform.environment['LIBRE_URL'] ?? 'https://libretranslate.com';
  final myMemoryEmail = opts['mymemory-email'] ?? Platform.environment['MYMEMORY_EMAIL'];
  final toList = (opts['to'] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  // Only require apiKey for paid providers
  if ((provider == 'google' || provider == 'azure') && (apiKey == null || apiKey.isEmpty)) {
    _log('error: missing --api-key (or set TRANSLATE_API_KEY)');
    exit(2);
  }
  if (toList.isEmpty) {
    _log('error: missing --to=fr,ar,...');
    exit(2);
  }

  final enFile = File('$translationsDir/en.json');
  if (!await enFile.exists()) {
    _log('error: $translationsDir/en.json not found');
    exit(2);
  }

  final enJson = json.decode(await enFile.readAsString()) as Map<String, dynamic>;
  final flatEn = _flatten(enJson);

  // Filter out empty values
  flatEn.removeWhere((k, v) => (v ?? '').toString().trim().isEmpty);

  for (final lang in toList) {
    if (lang == 'dua') {
      _log('info: skipping dua (Duala) – not supported by most APIs.');
      continue;
    }
    final targetPath = '$translationsDir/$lang.json';
    final existing = await _readJsonIfExists(targetPath);
    final flatExisting = _flatten(existing);

    // Find keys to translate
    final missingKeys = <String>[];
    flatEn.forEach((k, v) {
      if (!flatExisting.containsKey(k) || (flatExisting[k] ?? '').toString().isEmpty) {
        missingKeys.add(k);
      }
    });

    if (missingKeys.isEmpty) {
      _log('lang=$lang: nothing to do');
      continue;
    }

    _log('lang=$lang: translating ${missingKeys.length} strings via $provider');

    // Translate in small batches to respect quotas
    const batchSize = 50;
    for (var i = 0; i < missingKeys.length; i += batchSize) {
      final batchKeys = missingKeys.sublist(i, i + batchSize > missingKeys.length ? missingKeys.length : i + batchSize);
      final texts = batchKeys.map((k) => flatEn[k]!.toString()).toList();
      List<String> translations = List.filled(texts.length, '');
      if (provider == 'azure') {
        translations = await _azureTranslate(apiKey!, region, texts, lang);
      } else if (provider == 'google') {
        translations = await _googleTranslate(apiKey!, texts, lang);
      } else if (provider == 'libre') {
        translations = await _libreTranslate(libreUrl, texts, lang);
      } else if (provider == 'mymemory') {
        translations = await _myMemoryTranslate(texts, lang, myMemoryEmail);
      } else if (provider == 'auto') {
        // Try libre first, then fallback to mymemory, then google/azure if keys provided
        translations = await _libreTranslate(libreUrl, texts, lang);
        if (translations.where((t) => t.isNotEmpty).length != texts.length) {
          final mm = await _myMemoryTranslate(texts, lang, myMemoryEmail);
          for (var k = 0; k < translations.length && k < mm.length; k++) {
            if (translations[k].isEmpty) translations[k] = mm[k];
          }
        }
        // Optional fallback to paid providers if keys
        if ((apiKey != null && apiKey.isNotEmpty) && translations.where((t) => t.isNotEmpty).length != texts.length) {
          final paid = provider == 'azure'
              ? await _azureTranslate(apiKey, region, texts, lang)
              : await _googleTranslate(apiKey, texts, lang);
          for (var k = 0; k < translations.length && k < paid.length; k++) {
            if (translations[k].isEmpty) translations[k] = paid[k];
          }
        }
      }

      if (translations.length != batchKeys.length) {
        _log('warn: provider returned ${translations.length} items for batch of ${batchKeys.length}');
      }

      for (var j = 0; j < batchKeys.length && j < translations.length; j++) {
        flatExisting[batchKeys[j]] = translations[j];
      }
    }

    final merged = _unflatten({}..addAll(flatExisting));
    await File(targetPath).writeAsString(const JsonEncoder.withIndent('  ').convert(merged) + '\n');
    _log('lang=$lang: wrote $targetPath');
  }

  _log('done');
}

Future<Map<String, dynamic>> _readJsonIfExists(String path) async {
  final f = File(path);
  if (await f.exists()) {
    try {
      return json.decode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {}
  }
  return <String, dynamic>{};
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

Map<String, dynamic> _unflatten(Map<String, String> flat) {
  final Map<String, dynamic> out = {};
  for (final entry in flat.entries) {
    final parts = entry.key.split('.');
    Map<String, dynamic> curr = out;
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (i == parts.length - 1) {
        curr[p] = entry.value;
      } else {
        curr = (curr[p] as Map<String, dynamic>?) ?? <String, dynamic>{};
        // write back reference (since we created a new map possibly)
        (i == 0 ? out : _resolve(out, parts.take(i)))![p] = curr;
      }
    }
  }
  return out;
}

Map<String, dynamic>? _resolve(Map<String, dynamic> base, Iterable<String> parts) {
  Map<String, dynamic> curr = base;
  for (final p in parts) {
    curr = (curr[p] as Map<String, dynamic>) ;
  }
  return curr;
}

Future<List<String>> _googleTranslate(String apiKey, List<String> texts, String target) async {
  final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$apiKey');
  final body = json.encode({
    'q': texts,
    'target': target,
    'source': 'en',
    'format': 'text',
  });
  final httpClient = HttpClient();
  try {
    final req = await httpClient.postUrl(uri);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.add(utf8.encode(body));
    final res = await req.close();
    final resBody = await utf8.decodeStream(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = json.decode(resBody) as Map<String, dynamic>;
      final translations = (data['data']?['translations'] as List?) ?? const [];
      return translations.map((e) => (e['translatedText'] ?? '').toString()).toList();
    } else {
      _log('google error ${res.statusCode}: $resBody');
      return List.filled(texts.length, '');
    }
  } finally {
    httpClient.close(force: true);
  }
}

Future<List<String>> _azureTranslate(String apiKey, String? region, List<String> texts, String target) async {
  if (region == null || region.isEmpty) {
    _log('error: azure requires --region or TRANSLATE_REGION');
    return List.filled(texts.length, '');
  }
  final uri = Uri.parse('https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=$target');
  final payload = json.encode(texts.map((t) => {'Text': t}).toList());
  final httpClient = HttpClient();
  try {
    final req = await httpClient.postUrl(uri);
    req.headers.set('Ocp-Apim-Subscription-Key', apiKey);
    req.headers.set('Ocp-Apim-Subscription-Region', region);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.add(utf8.encode(payload));
    final res = await req.close();
    final resBody = await utf8.decodeStream(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = json.decode(resBody) as List<dynamic>;
      return data.map((item) {
        final translations = (item['translations'] as List?) ?? const [];
        return translations.isNotEmpty ? translations.first['text'].toString() : '';
      }).toList();
    } else {
      _log('azure error ${res.statusCode}: $resBody');
      return List.filled(texts.length, '');
    }
  } finally {
    httpClient.close(force: true);
  }
}

// LibreTranslate free provider (public instances are rate-limited).
// Default baseUrl can be overridden with --libre-url or LIBRE_URL env.
Future<List<String>> _libreTranslate(String baseUrl, List<String> texts, String target) async {
  final httpClient = HttpClient();
  final out = <String>[];
  for (final text in texts) {
    try {
      final uri = Uri.parse(_joinUrl(baseUrl, '/translate'));
      final body = json.encode({
        'q': text,
        'source': 'en',
        'target': target,
        'format': 'text',
      });
      final req = await httpClient.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(body));
      final res = await req.close();
      final resBody = await utf8.decodeStream(res);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(resBody) as Map<String, dynamic>;
        out.add((data['translatedText'] ?? '').toString());
      } else {
        _log('libre error ${res.statusCode}: $resBody');
        out.add('');
      }
    } catch (e) {
      _log('libre error: $e');
      out.add('');
    }
  }
  httpClient.close(force: true);
  return out;
}

// MyMemory free provider: limited daily quota; add contact email to increase fairness.
// GET https://api.mymemory.translated.net/get?q=...&langpair=en|<target>[&de=email]
Future<List<String>> _myMemoryTranslate(List<String> texts, String target, String? email) async {
  final httpClient = HttpClient();
  final out = <String>[];
  for (final text in texts) {
    try {
      final q = Uri.encodeQueryComponent(text);
      final langpair = 'en|$target';
      final de = (email != null && email.isNotEmpty) ? '&de=${Uri.encodeQueryComponent(email)}' : '';
      final uri = Uri.parse('https://api.mymemory.translated.net/get?q=$q&langpair=$langpair$de');
      final req = await httpClient.getUrl(uri);
      final res = await req.close();
      final resBody = await utf8.decodeStream(res);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(resBody) as Map<String, dynamic>;
        final translated = data['responseData']?['translatedText']?.toString() ?? '';
        out.add(translated);
      } else {
        _log('mymemory error ${res.statusCode}: $resBody');
        out.add('');
      }
    } catch (e) {
      _log('mymemory error: $e');
      out.add('');
    }
  }
  httpClient.close(force: true);
  return out;
}

String _joinUrl(String base, String path) {
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  if (!path.startsWith('/')) path = '/$path';
  return '$base$path';
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

void _log(String msg) {
  // ignore: avoid_print
  print('[translate] $msg');
}
