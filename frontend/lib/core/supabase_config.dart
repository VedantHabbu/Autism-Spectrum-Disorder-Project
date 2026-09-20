/// Supabase connection settings, supplied at build time.
///
/// Never hardcoded and never committed. Pass them the same way as
/// API_BASE_URL:
///
///   flutter run \
///     `--dart-define=SUPABASE_URL=https://<project-ref>.supabase.co` \
///     `--dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key>`
///
/// Only the *publishable* key belongs here. It is safe for clients because
/// Row-Level Security is what protects the data. The secret/service-role
/// key bypasses RLS entirely and must never reach the app.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

const String supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

bool get hasSupabaseConfig =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

/// Shown instead of crashing when the app is built without configuration.
const String supabaseConfigMissingMessage =
    'Supabase configuration is missing. Rebuild with:\n\n'
    '  --dart-define=SUPABASE_URL=...\n'
    '  --dart-define=SUPABASE_PUBLISHABLE_KEY=...';
