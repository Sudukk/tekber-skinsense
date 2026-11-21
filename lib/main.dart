import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens/guide.dart';
import 'screens/home.dart';
import 'services.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const SkinSenseApp());
}

GoRouter createRouter({String initialLocation = '/home'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => _NavShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            GoRoute(
              path: '/history',
              builder: (_, _) => const _PlaceholderScreen(
                title: 'Riwayat',
                subtitle: 'Halaman riwayat pemeriksaan akan ditambahkan pada fitur Riwayat.',
              ),
            ),
            GoRoute(path: '/guide', builder: (_, _) => const GuideScreen()),
            GoRoute(path: '/profile', builder: (_, _) => const _ProfilePlaceholderScreen()),
            GoRoute(
              path: '/process',
              builder: (_, _) => const _PlaceholderScreen(
                title: 'Pemindaian Lesi',
                subtitle: 'Halaman pemindaian lesi kulit akan ditambahkan pada fitur Pemindaian.',
              ),
            ),
          ],
        ),
      ],
    );

class SkinSenseApp extends StatefulWidget {
  const SkinSenseApp({super.key, this.initialLocation = '/home'});
  final String initialLocation;

  @override
  State<SkinSenseApp> createState() => _SkinSenseAppState();
}

class _SkinSenseAppState extends State<SkinSenseApp> {
  late final GoRouter _router = createRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: StateMessage(title: title, text: subtitle),
      );
}

class _ProfilePlaceholderScreen extends StatefulWidget {
  const _ProfilePlaceholderScreen();

  @override
  State<_ProfilePlaceholderScreen> createState() => _ProfilePlaceholderScreenState();
}

class _ProfilePlaceholderScreenState extends State<_ProfilePlaceholderScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = '';
  String _birthDate = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await getCurrentUserProfile();
    if (!mounted) return;
    _nameController.text = (profile['full_name'] as String?) ?? '';
    _phoneController.text = (profile['phone'] as String?) ?? '';
    setState(() {
      _gender = (profile['gender'] as String?) ?? '';
      _birthDate = (profile['birth_date'] as String?) ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await updateCurrentUserProfile(
      fullName: _nameController.text.trim(),
      gender: _gender,
      birthDate: _birthDate,
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sementara diperbarui.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return FormScreen(
      bottomInset: false,
      children: [
        screenTitle('Profil', 'Lengkapi data akun yang digunakan pada laporan hasil.'),
        AppField(label: 'Nama Lengkap', controller: _nameController, hint: 'Masukkan nama lengkap'),
        GenderField(value: _gender, onChanged: (v) => setState(() => _gender = v)),
        BirthDateField(value: _birthDate, onChanged: (v) => setState(() => _birthDate = v)),
        AppField(
          label: 'Nomor Telepon',
          controller: _phoneController,
          hint: '08xxxxxxxxxx',
          keyboardType: TextInputType.phone,
        ),
        AppButton(title: 'Simpan Profil', onPressed: _save),
      ],
    );
  }
}
