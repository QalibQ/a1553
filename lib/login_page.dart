import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'reset_password_page.dart';
import 'app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _isSignUp = false;
  /// 0 = email/password, 1 = username (sign-up only).
  int _signUpStep = 0;
  int _resendCooldownSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool _isValidUsername(String raw) {
    final s = raw.trim();
    if (s.length < 2 || s.length > 32) return false;
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s);
  }

  void _goToUsernameStep() {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in email and password first')),
      );
      return;
    }
    setState(() => _signUpStep = 1);
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendCooldownSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
      } else {
        setState(() => _resendCooldownSeconds -= 1);
      }
    });
  }

  Future<void> _resendConfirmationEmail() async {
    if (_resendCooldownSeconds > 0) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabaseService.resendSignUpConfirmationEmail(email);
      _startResendCooldown(60);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation email sent. Please check your inbox.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignUp() async {
    final username = _usernameController.text;
    if (!_isValidUsername(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username: 2–32 characters, letters, numbers, and underscores only.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        username: username.trim(),
      );
      if (mounted) {
        setState(() {
          _signUpStep = 0;
          _usernameController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please check your email to confirm your account.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    if (_isSignUp) {
      if (_signUpStep == 0) {
        _goToUsernameStep();
        return;
      }
      await _completeSignUp();
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabaseService.signIn(_emailController.text, _passwordController.text);
      // AuthGate in main.dart will automatically redirect to EsasEkran on success
    } on AuthException catch (e) {
      // This catches specific Supabase Auth errors like "Email not confirmed" or "Invalid credentials"
      if (mounted) {
        final isNotConfirmed = e.message.toLowerCase().contains('email not confirmed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNotConfirmed
                  ? 'Email not confirmed. Check your inbox or tap "Resend confirmation email".'
                  : e.message,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ResetPasswordPage(
          prefillEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF0F172A);
    final secondary = const Color(0xFF1E293B);
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Top gradient header to match main screen styling.
          Container(
            height: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, secondary],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSignUp ? 'Create Account' : 'Welcome Back',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp
                            ? (_signUpStep == 0
                                ? 'Start mastering system design in minutes.'
                                : 'Choose a username — it will appear on your account screen.')
                            : 'Sign in to continue your system design journey.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cs.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isSignUp && _signUpStep == 1) ...[
                              Text(
                                'Signed up as',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _emailController.text.trim(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _usernameController,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.username],
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'letters, numbers, underscores',
                                  prefixIcon: const Icon(Icons.alternate_email),
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: primary.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                          _signUpStep = 0;
                                          _usernameController.clear();
                                        }),
                                child: const Text('Back'),
                              ),
                              const SizedBox(height: 8),
                            ] else ...[
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: primary.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                autofillHints: const [AutofillHints.password],
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: primary.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _isLoading
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleAuth,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      !_isSignUp
                                          ? 'Sign in'
                                          : (_signUpStep == 0 ? 'Continue' : 'Create account'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 10),
                            if (!_isSignUp)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _forgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    foregroundColor: primary,
                                  ),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            if (!_isSignUp)
                              TextButton(
                                onPressed: (_isLoading || _resendCooldownSeconds > 0)
                                    ? null
                                    : _resendConfirmationEmail,
                                child: Text(
                                  _resendCooldownSeconds > 0
                                      ? 'Resend confirmation email (${_resendCooldownSeconds}s)'
                                      : 'Resend confirmation email',
                                  style: TextStyle(color: primary),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _signUpStep = 0;
                                  _usernameController.clear();
                                }),
                        style: TextButton.styleFrom(
                          foregroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _isSignUp ? 'Already have an account? Sign in' : 'Need an account? Create one',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By continuing, you agree to our Terms and Privacy Policy.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    tooltip: 'Dark mode',
                    onPressed: () {
                      final c = AppThemeScope.of(context);
                      c.setDark(!c.isDark);
                    },
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
