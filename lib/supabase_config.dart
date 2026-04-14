class SupabaseConfig {
  // Option A (simple local setup): paste real values below once.
  static const String _fallbackUrl = 'https://lsjfssthhtjhljwtwiwg.supabase.co';
  static const String _fallbackAnonKey =
      'sb_publishable_6BlXgDZVz0IBIo5Oas89XQ_NLWOtLDo';

  // Option B (production/deploy): pass values with --dart-define.
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get url => _envUrl.isNotEmpty ? _envUrl : _fallbackUrl;
  static String get anonKey =>
      _envAnonKey.isNotEmpty ? _envAnonKey : _fallbackAnonKey;

  // Stripe Key (Optional for initialization but needed for your payment flow)
  static const String stripePublishableKey = "pk_test_your_key_here";
  static const String stripePriceIdMonthly = String.fromEnvironment(
    'STRIPE_PRICE_ID_MONTHLY',
    defaultValue: 'price_monthly_placeholder',
  );
  static const String stripePriceIdYearly = String.fromEnvironment(
    'STRIPE_PRICE_ID_YEARLY',
    defaultValue: 'price_yearly_placeholder',
  );
  static const String stripePriceIdLifetime = String.fromEnvironment(
    'STRIPE_PRICE_ID_LIFETIME',
    defaultValue: 'price_lifetime_placeholder',
  );

  static bool get isConfigured {
    final normalizedUrl = url.trim();
    final normalizedKey = anonKey.trim();
    final lowerUrl = normalizedUrl.toLowerCase();
    final lowerKey = normalizedKey.toLowerCase();
    final validUrl = normalizedUrl.startsWith('https://') &&
        normalizedUrl.contains('.supabase.co') &&
        !lowerUrl.contains('your_project_ref') &&
        !lowerUrl.contains('<project-ref>') &&
        !lowerUrl.contains('abc123xyz');
    // Supabase client keys can be legacy JWT anon keys or sb_publishable_* keys.
    final validAnonKey = normalizedKey.isNotEmpty &&
        (normalizedKey.split('.').length == 3 ||
            normalizedKey.startsWith('sb_publishable_')) &&
        !lowerKey.contains('your_anon_key') &&
        !lowerKey.contains('your_supabase_anon_key') &&
        !lowerKey.contains('your-real-anon-key') &&
        !lowerKey.contains('your_actual_key_here');
    return validUrl && validAnonKey;
  }

  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Provide SUPABASE_URL and '
        'SUPABASE_ANON_KEY via --dart-define or replace values in '
        'lib/supabase_config.dart.',
      );
    }
  }
}
