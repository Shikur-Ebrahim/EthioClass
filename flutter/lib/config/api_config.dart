/// API configuration for the EthioClass application.
///
/// The base URL is configurable at build time using --dart-define:
///   flutter run --dart-define=API_BASE_URL=https://api.ethioclass.com
///
/// Default: https://api.ethioclass.com (production cloud backend via Cloudflare)
/// Do NOT hardcode localhost — the real backend runs on Contabo VPS.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.ethioclass.com',
);
