import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _loadingPremium = true;
  bool _isPremium = false;
  String? _displayUsername;

  @override
  void initState() {
    super.initState();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingPremium = false);
      return;
    }

    String? nameFromMeta(String? m) {
      final s = m?.trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    try {
      final usersRes = await Supabase.instance.client
          .from('users')
          .select('is_premium, username')
          .eq('id', user.id)
          .maybeSingle();
      final res = usersRes ??
          await Supabase.instance.client
              .from('profiles')
              .select('is_premium, username')
              .eq('id', user.id)
              .maybeSingle();

      final fromRow = nameFromMeta(res?['username'] as String?);
      final fromMeta = nameFromMeta(user.userMetadata?['username'] as String?);
      final display = fromRow ?? fromMeta ?? user.email?.split('@').first ?? 'User';

      if (mounted) {
        setState(() {
          _isPremium = (res?['is_premium'] as bool?) ?? false;
          _displayUsername = display;
          _loadingPremium = false;
        });
      }
    } catch (_) {
      final fromMeta = nameFromMeta(user.userMetadata?['username'] as String?);
      final display = fromMeta ?? user.email?.split('@').first ?? 'User';
      if (mounted) {
        setState(() {
          _isPremium = false;
          _displayUsername = display;
          _loadingPremium = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (mounted) Navigator.of(context).pop();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Signed in';
    final metaUser = (user?.userMetadata?['username'] as String?)?.trim();
    final displayName = (_displayUsername != null && _displayUsername!.isNotEmpty)
        ? _displayUsername!
        : ((metaUser != null && metaUser.isNotEmpty)
            ? metaUser
            : (email.contains('@') ? email.split('@').first : email));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeCtrl = AppThemeScope.of(context);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _loadingPremium
                        ? Icons.hourglass_empty
                        : (_isPremium ? Icons.workspace_premium : Icons.lock_open),
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _loadingPremium
                          ? 'Checking plan…'
                          : (_isPremium ? 'Premium active' : 'Free plan'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              themeCtrl.isDark ? Icons.dark_mode : Icons.light_mode,
              color: cs.primary,
            ),
            title: const Text('Dark mode'),
            value: themeCtrl.isDark,
            onChanged: (v) => themeCtrl.setDark(v),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
