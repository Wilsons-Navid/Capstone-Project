/// Configuration for the Wilson AI Cloudflare Worker backend.
///
/// The Worker (in `wilson-worker/`) holds the Claude API key, verifies the
/// Firebase ID token, and proxies to Claude Haiku. This replaces the Firebase
/// Cloud Functions path, which requires the paid Blaze plan.
///
/// After deploying the Worker (`npm run deploy` in `wilson-worker/`), wrangler
/// prints a URL like `https://wilson-worker.<subdomain>.workers.dev`. Paste it
/// below.
class WilsonWorkerConfig {
  WilsonWorkerConfig._();

  /// Base URL of the deployed Worker. No trailing slash.
  ///
  static const String baseUrl = 'https://wilson-worker.wilson-worker.workers.dev';

  static const String chatPath = '/chat';
  static const String analyzePath = '/analyze';
  static const String insightsPath = '/insights';
  static const String threatIntelPath = '/threat-intel';
  static const String trainingPath = '/training';

  /// True once a real Worker URL has been configured.
  static bool get isConfigured => !baseUrl.contains('CHANGEME');
}
