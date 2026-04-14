import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Forgot password: **email only** → Supabase sends a **link** → user opens link
/// and enters new password **twice** here ([openedFromRecoveryEmailLink]).
/// After saving, they are signed out and return to **login** with email + new password.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    this.prefillEmail,
    this.openedFromRecoveryEmailLink = false,
  });

  final String? prefillEmail;

  /// True when the user opened the reset link from email (recovery session active).
  final bool openedFromRecoveryEmailLink;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _supabaseService = SupabaseService();

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;

  Color get _primary => const Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    if (widget.openedFromRecoveryEmailLink) {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
    } else if (widget.prefillEmail != null && widget.prefillEmail!.trim().isNotEmpty) {
      _emailController.text = widget.prefillEmail!.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _supabaseService.requestPasswordRecoveryCode(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists, we sent a link. Open it, set your new password twice, then use Back and sign in.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNewPassword() async {
    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;
    if (p1.isEmpty || p2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both password fields')),
      );
      return;
    }
    if (p1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password should be at least 6 characters')),
      );
      return;
    }
    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _supabaseService.updatePassword(p1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password saved. Return to the app and sign in with your email and new password.'),
          backgroundColor: Colors.blue,
        ),
      );
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recovery = widget.openedFromRecoveryEmailLink;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(recovery ? 'Choose new password' : 'Forgot password'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    recovery ? 'Set your new password' : 'We’ll email you a link',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recovery
                        ? 'Enter your new password twice, then go back to the app and sign in with the same email and this new password.'
                        : 'Enter the email for your account. We’ll send a link — open it to type your new password twice, then return here to sign in.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!recovery) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _fieldDecoration(context, 'Email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    _primaryButton(
                      label: 'Send reset link',
                      loading: _loading,
                      onPressed: _sendResetLink,
                    ),
                  ] else ...[
                    if (_emailController.text.isNotEmpty) ...[
                      Text(
                        _emailController.text,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _fieldDecoration(
                        context,
                        'New password',
                        Icons.lock_reset_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _fieldDecoration(
                        context,
                        'Confirm new password',
                        Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _primaryButton(
                      label: 'Save password',
                      loading: _loading,
                      onPressed: _saveNewPassword,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
