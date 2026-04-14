import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static const String defaultMobileRecoveryRedirect = 'a1553://reset';

  // Authentication
  /// [username] is stored in user metadata and, if you run migrations, copied to `public.users.username`.
  Future<AuthResponse> signUp(
    String email,
    String password, {
    String? username,
  }) async {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) {
      return _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': u},
      );
    }
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resendSignUpConfirmationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Sends a password-reset **email with a link** (Supabase “Reset password” template).
  ///
  /// On web, [redirectTo] defaults to [Uri.base.origin] so the link opens this app.
  /// Add that URL (and optional `--dart-define=AUTH_REDIRECT_URL=...`) under Auth → URL Configuration in Supabase.
  Future<void> requestPasswordRecoveryCode(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _passwordRecoveryRedirectTo(),
    );
  }

  String? _passwordRecoveryRedirectTo() {
    const fromEnv = String.fromEnvironment('AUTH_REDIRECT_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) {
      final o = Uri.base.origin;
      return o.endsWith('/') ? o.substring(0, o.length - 1) : o;
    }
    // Mobile deep link fallback (must be added to Supabase Redirect URLs).
    return defaultMobileRecoveryRedirect;
  }

  /// Verify the 6-digit code from the recovery email (`OtpType.recovery`).
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Updates display name in Auth metadata and `public.users` when available.
  Future<void> updateDisplayUsername(String username) async {
    final u = currentUser;
    if (u == null) return;
    final trimmed = username.trim();
    await _client.auth.updateUser(
      UserAttributes(data: {'username': trimmed}),
    );
    try {
      await _client.from('users').update({'username': trimmed}).eq('id', u.id);
    } catch (_) {}
  }

  User? get currentUser => _client.auth.currentUser;

  // Profiles
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final usersResponse =
        await _client.from('users').select().eq('id', user.id).maybeSingle();
    if (usersResponse != null) return usersResponse;

    final profilesResponse =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    return profilesResponse;
  }

  // Content
  Future<List<Map<String, dynamic>>> getContent() async {
    final response = await _client
        .from('content')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Stripe
  Future<String?> createCheckoutSession(String priceId) async {
    try {
      final response = await _client.functions.invoke(
        'create-checkout-session',
        body: {'priceId': priceId},
      );

      if (response.status == 200 && response.data is Map<String, dynamic>) {
        return response.data['url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Admin Functionality
  Future<void> createContent({
    required String title,
    String? description,
    bool premiumOnly = false,
  }) async {
    await _client.from('content').insert({
      'title': title,
      'description': description,
      'premium_only': premiumOnly,
    });
  }
}
