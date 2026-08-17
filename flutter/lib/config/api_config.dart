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

/// The Cloudflare R2 public domain used to display uploaded images.
const String r2PublicUrl = String.fromEnvironment(
  'R2_PUBLIC_URL',
  defaultValue: 'https://pub-a58ed9ccf9f9786d955bd8be887bf1b3.r2.dev',
);
