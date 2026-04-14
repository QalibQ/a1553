import 'dart:ui';

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'topic_detail_page.dart';
import 'payment_page.dart';
import 'topic_model.dart';
import 'login_page.dart';
import 'account_page.dart';
import 'app_theme.dart';
import 'reset_password_page.dart';
import 'supabase_config.dart';
import 'auth_recovery_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = AppThemeController();
  await themeController.load();

  if (!SupabaseConfig.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(MyApp(themeController: themeController));
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Supabase is not configured',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Set real values for SUPABASE_URL and SUPABASE_ANON_KEY.\n\n'
                    'Option A: put values in lib/supabase_config.dart\n'
                    'Option B: run with --dart-define:\n'
                    'flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co '
                    '--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final List<Topic> allTopics = [
  const Topic(id: "1", title: "Netflix Global Scale", description: "Architecting for 200M+ concurrent viewers and CDN strategies.", difficulty: "Hard", isPremium: true, category: "Full Case Library", domain: "Streaming"),
  const Topic(id: "2", title: "YouTube Video Upload", description: "Large file processing, transcoding, and distributed storage.", difficulty: "Medium", isPremium: false, category: "Architecture Template", domain: "Streaming"),
  const Topic(id: "3", title: "Twitter Feed System", description: "Fan-out on write vs read and timeline consistency.", difficulty: "Hard", isPremium: false, category: "Case Study", domain: "Social Media"),
  const Topic(id: "4", title: "WhatsApp Real-time Messaging", description: "Handling billions of messages with Erlang and XMPP.", difficulty: "Hard", isPremium: true, category: "Case Study", domain: "Social Media"),
  const Topic(id: "5", title: "Instagram Photo Feed", description: "Image sharding, thumbnail generation, and caching.", difficulty: "Medium", isPremium: false, category: "Architecture Template", domain: "Social Media"),
  const Topic(id: "6", title: "Stripe Payment Gateway", description: "Idempotency, PCI compliance, and distributed transactions.", difficulty: "Hard", isPremium: true, category: "Full Case Library", domain: "Fintech"),
  const Topic(id: "7", title: "Crypto Exchange Matching Engine", description: "In-memory processing for ultra-low latency trading.", difficulty: "Hard", isPremium: true, category: "Senior Pack", domain: "Fintech"),
  const Topic(id: "8", title: "Amazon Flash Sale", description: "Handling sudden 100x traffic spikes and inventory locks.", difficulty: "Hard", isPremium: true, category: "Scaling Pattern", domain: "E-commerce"),
  const Topic(id: "9", title: "Search Auto-complete", description: "Trie data structures and distributed indexing for speed.", difficulty: "Medium", isPremium: false, category: "Architecture Template", domain: "E-commerce"),
  const Topic(id: "10", title: "Load Balancing 101", description: "L4 vs L7 balancing and health check algorithms.", difficulty: "Easy", isPremium: false, category: "Scaling Pattern", domain: "Infrastructure"),
  const Topic(id: "11", title: "Distributed Caching", description: "Write-through, write-around, and write-back policies.", difficulty: "Medium", isPremium: false, category: "Caching Strategy", domain: "Infrastructure"),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final AppThemeController themeController;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        brightness: Brightness.light,
      ),
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    );
  }

  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        brightness: Brightness.dark,
      ),
      brightness: Brightness.dark,
      fontFamily: 'Inter',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: "System Design Pro",
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
          ),
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeController.themeMode,
          builder: (context, child) {
            return AppThemeScope(
              notifier: themeController,
              child: AuthRecoveryNavigator(
                navigatorKey: navigatorKey,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Ensures that when a Supabase recovery link opens the app (deep link),
/// we always navigate to the reset-password screen, even if the app initially
/// renders the default route first.
class AuthRecoveryNavigator extends StatefulWidget {
  const AuthRecoveryNavigator({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AuthRecoveryNavigator> createState() => _AuthRecoveryNavigatorState();
}

class _AuthRecoveryNavigatorState extends State<AuthRecoveryNavigator> {
  StreamSubscription<AuthState>? _sub;
  StreamSubscription<Uri?>? _linkSub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _startLinkHandling();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      // PKCE recovery sometimes emits signedIn; JWT amr still has method recovery.
      if (state.event == AuthChangeEvent.passwordRecovery ||
          isPasswordRecoverySession(state.session)) {
        _pushResetPassword();
      }
    });
  }

  void _pushResetPassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordPage(openedFromRecoveryEmailLink: true),
        ),
        (route) => false,
      );
    });
  }

  void _showDebugSnack(String message) {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startLinkHandling() async {
    // Handle cold start link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        final s = Supabase.instance.client.auth.currentSession;
        if (isPasswordRecoverySession(s)) {
          _pushResetPassword();
        }
      }
    } catch (e) {
      _showDebugSnack('Reset link error (initial): $e');
    }

    // Handle warm links
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        final s = Supabase.instance.client.auth.currentSession;
        if (isPasswordRecoverySession(s)) {
          _pushResetPassword();
        }
      } catch (e) {
        _showDebugSnack('Reset link error: $e');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final session = state?.session;
        final event = state?.event;

        // Recovery email link: session exists but user must set a new password first.
        if (session != null &&
            (event == AuthChangeEvent.passwordRecovery ||
                isPasswordRecoverySession(session))) {
          return const ResetPasswordPage(openedFromRecoveryEmailLink: true);
        }
        if (session != null) {
          return const EsasEkran();
        }
        return const LoginPage();
      },
    );
  }
}

class EsasEkran extends StatefulWidget {
  const EsasEkran({super.key});
  @override
  State<EsasEkran> createState() => _EsasEkranState();
}

class _EsasEkranState extends State<EsasEkran> with TickerProviderStateMixin {
  String searchQuery = "";
  String selectedDomain = "All";
  final Set<String> bookmarkedIds = {};
  bool showBookmarksOnly = false;
  bool isPremiumUser = false;

  late TabController _difficultyTabController;
  late TabController _domainTabController;

  final List<String> domains = ["All", "Social Media", "E-commerce", "Streaming", "Fintech", "Infrastructure"];

  @override
  void initState() {
    super.initState();
    _difficultyTabController = TabController(length: 4, vsync: this);
    _domainTabController = TabController(length: domains.length, vsync: this);
    _domainTabController.addListener(() {
      if (!_domainTabController.indexIsChanging) setState(() => selectedDomain = domains[_domainTabController.index]);
    });
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final usersRes = await Supabase.instance.client
            .from('users')
            .select('is_premium')
            .eq('id', user.id)
            .maybeSingle();
        final res = usersRes ??
            await Supabase.instance.client
                .from('profiles')
                .select('is_premium')
                .eq('id', user.id)
                .maybeSingle();
        if (!mounted) return;
        setState(() => isPremiumUser = (res?['is_premium'] as bool?) ?? false);
      } catch (_) {
        // Keep app usable even if profile row/table is not ready yet.
        if (!mounted) return;
        setState(() => isPremiumUser = false);
      }
    }
  }

  @override
  void dispose() {
    _difficultyTabController.dispose();
    _domainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF0F172A),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text("Architect's Vault", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                                        if (isPremiumUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                            child: const Text("PREMIUM", style: TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(showBookmarksOnly ? "Your Bookmarks" : "Master System Design", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Bookmarks',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    icon: Icon(showBookmarksOnly ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 24),
                                    onPressed: () => setState(() => showBookmarksOnly = !showBookmarksOnly),
                                  ),
                                  IconButton(
                                    tooltip: 'Account',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 24),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(builder: (context) => const AccountPage()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(hintText: "Search 100+ cases...", hintStyle: TextStyle(color: Colors.white38), prefixIcon: Icon(Icons.search, color: Colors.white38), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.1)),
                      child: TabBar(
                        controller: _domainTabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: const Color(0xFF0F172A),
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        indicator: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white),
                        tabs: domains.map((d) => Tab(text: d)).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.1)),
                      child: TabBar(
                        controller: _difficultyTabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: const Color(0xFF0F172A),
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        indicator: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white),
                        tabs: const [Tab(text: "All"), Tab(text: "Easy"), Tab(text: "Medium"), Tab(text: "Hard")],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ];
        },
        body: showBookmarksOnly
          ? _buildFilteredList(null, forceBookmarks: true)
          : TabBarView(
              controller: _difficultyTabController,
              children: [_buildFilteredList(null), _buildFilteredList("Easy"), _buildFilteredList("Medium"), _buildFilteredList("Hard")],
            ),
      ),
    );
  }

  void _showPlanSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.workspace_premium, color: Theme.of(dialogContext).colorScheme.primary), const SizedBox(width: 12), const Text("Unlock Senior Pack", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose a plan to elevate your architecture skills:"),
            const SizedBox(height: 20),
            _buildPlanTile(
              dialogContext,
              "Monthly",
              r"$9.99",
              priceId: SupabaseConfig.stripePriceIdMonthly,
            ),
            _buildPlanTile(
              dialogContext,
              "Yearly",
              r"$59",
              subtitle: "Save 50%",
              priceId: SupabaseConfig.stripePriceIdYearly,
            ),
            _buildPlanTile(
              dialogContext,
              "Lifetime",
              r"$79",
              subtitle: "Early user special",
              priceId: SupabaseConfig.stripePriceIdLifetime,
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("CANCEL", style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)))],
      ),
    );
  }

  Widget _buildPlanTile(
    BuildContext context,
    String title,
    String price, {
    String? subtitle,
    required String priceId,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12)) : null,
        trailing: Text(price, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
        onTap: () async {
          if (!priceId.startsWith('price_') || priceId.contains('placeholder')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Stripe price id is not configured for this plan.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          Navigator.pop(context);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentPage(planName: title, price: price, priceId: priceId),
            ),
          );
          if (result == true) _checkPremiumStatus();
        },
      ),
    );
  }

  Widget _buildFilteredList(String? difficulty, {bool forceBookmarks = false}) {
    List<Topic> filtered = allTopics.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(searchQuery) || t.domain.toLowerCase().contains(searchQuery);
      final matchesDomain = selectedDomain == "All" || t.domain == selectedDomain;
      final matchesDifficulty = difficulty == null || t.difficulty == difficulty;
      final matchesBookmark = !forceBookmarks || bookmarkedIds.contains(t.id);
      return matchesSearch && matchesDomain && matchesDifficulty && matchesBookmark;
    }).toList();

    return TopicList(
      topics: filtered,
      showDifficulty: difficulty == null,
      isPremiumUser: isPremiumUser,
      onBookmark: (id) => setState(() => bookmarkedIds.contains(id) ? bookmarkedIds.remove(id) : bookmarkedIds.add(id)),
      bookmarkedIds: bookmarkedIds,
      onTap: (topic) async {
        if (topic.isPremium && !isPremiumUser) {
          _showPlanSelector(context);
        } else {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TopicDetailPage(topic: topic, isPremiumUser: isPremiumUser)));
          if (result == true) _checkPremiumStatus();
        }
      },
    );
  }
}

class TopicList extends StatelessWidget {
  final List<Topic> topics;
  final bool showDifficulty;
  final bool isPremiumUser;
  final Function(String) onBookmark;
  final Set<String> bookmarkedIds;
  final Function(Topic) onTap;

  const TopicList({super.key, required this.topics, this.showDifficulty = false, required this.isPremiumUser, required this.onBookmark, required this.bookmarkedIds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (topics.isEmpty) {
      return Center(child: Text("No architectures found", style: TextStyle(color: cs.onSurfaceVariant)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final isBookmarked = bookmarkedIds.contains(topic.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: cs.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(topic),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                            child: Text(topic.domain.toUpperCase(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          if (topic.isPremium && !isPremiumUser) Icon(Icons.lock_outline, size: 14, color: cs.outline),
                        ]),
                        const SizedBox(height: 8),
                        Text(topic.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: cs.onSurface)),
                        const SizedBox(height: 4),
                        Text(topic.description, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(children: [
                          _buildMiniTag(context, topic.category, cs.surfaceContainerHighest),
                          if (showDifficulty) ...[const SizedBox(width: 6), _buildMiniTag(context, topic.difficulty, cs.surfaceContainerLow)],
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: cs.primary),
                    onPressed: () => onBookmark(topic.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniTag(BuildContext context, String text, Color background) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
