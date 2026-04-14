// This service is now deprecated in favor of Supabase + Stripe.
// Keeping it with empty logic to prevent build errors in legacy code.

class RevenueCatService {
  static Future<void> init() async {
    // Supabase + Stripe replaces RevenueCat initialization.
  }

  static Future<bool> isUserPremium() async {
    // Check Supabase profiles table instead.
    return false;
  }
}
