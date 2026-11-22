import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth.dart';
import 'screens/guide.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Supabase.initialize(
    url: isSupabaseConfigured ? supabaseUrl : 'https://placeholder.supabase.co',
    publishableKey: isSupabaseConfigured ? supabaseKey : 'placeholder-anon-key',
  );
  runApp(const SkinSenseApp());
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _subscription = supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

const _publicRoutes = {'/', '/login', '/register'};

final _router = GoRouter(
  refreshListenable: _AuthListenable(),
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final path = state.uri.path;
    if (path == '/auth/callback') return null;
    if (loggedIn && _publicRoutes.contains(path)) return '/home';
    if (!loggedIn && !_publicRoutes.contains(path)) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, _) => const LandingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/auth/callback', builder: (_, state) => AuthCallbackScreen(params: state.uri.queryParameters)),
    ShellRoute(
      builder: (context, state, child) => _NavShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/history', builder: (_, _) => const _Placeholder('Riwayat')),
        GoRoute(path: '/guide', builder: (_, _) => const GuideScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(path: '/edit-profile', builder: (_, _) => const EditProfileScreen()),
        GoRoute(path: '/process', builder: (_, _) => const _Placeholder('Pemindaian Lesi')),
      ],
    ),
  ],
);

class SkinSenseApp extends StatelessWidget {
  const SkinSenseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'SkinSense',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routerConfig: _router,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      );
}

const _navItems = [
  ('Periksa', '/home', LucideIcons.scanLine),
  ('Riwayat', '/history', LucideIcons.history),
  ('Panduan', '/guide', LucideIcons.bookOpen),
  ('Profil', '/profile', LucideIcons.circleUserRound),
];

class _NavShell extends StatelessWidget {
  const _NavShell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PopScope(
          canPop: location == '/home',
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go('/home');
          },
          child: child,
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: AppColors.line, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  for (final (label, route, icon) in _navItems)
                    Expanded(child: _NavItem(label: label, icon: icon, active: location == route, route: route)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.active, required this.route});
  final String label;
  final IconData icon;
  final bool active;
  final String route;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: active,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: active ? null : () => context.go(route),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: active ? AppColors.teal : AppColors.inkFaint),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.tealDeep : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
