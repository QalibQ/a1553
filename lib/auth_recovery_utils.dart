import 'package:jwt_decode/jwt_decode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True when the access token was issued for a password-recovery session.
///
/// Supabase sometimes emits [AuthChangeEvent.signedIn] (e.g. PKCE) instead of
/// [AuthChangeEvent.passwordRecovery], but the JWT `amr` still lists
/// `{ "method": "recovery", ... }`.
bool isPasswordRecoverySession(Session? session) {
  if (session == null) return false;
  try {
    final payload = Jwt.parseJwt(session.accessToken);
    final amr = payload['amr'];
    if (amr is! List) return false;
    for (final entry in amr) {
      if (entry is Map && entry['method'] == 'recovery') return true;
    }
  } catch (_) {}
  return false;
}
