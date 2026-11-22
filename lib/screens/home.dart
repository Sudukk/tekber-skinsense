import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../logic.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

enum LoadStatus { loading, success, error, incomplete }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  LoadStatus _status = LoadStatus.loading;
  Future<void>? _inFlight;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool showLoading = false}) => _inFlight ??= (() async {
        if (showLoading) setState(() => _status = LoadStatus.loading);
        try {
          final profile = await getCurrentUserProfile();
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _status = isProfileComplete(profile) ? LoadStatus.success : LoadStatus.incomplete;
          });
        } catch (_) {
          if (mounted) setState(() => _status = LoadStatus.error);
        }
      })().whenComplete(() => _inFlight = null);

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final complete = isProfileComplete(_profile);
    final fullName = normalizeText(_profile?['full_name'] as String?);
    final firstName = fullName.isEmpty ? 'User' : fullName.split(RegExp(r'\s+')).first;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo,', style: AppText.body.copyWith(color: AppColors.inkMuted)),
                      Text(firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title.copyWith(color: AppColors.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset('assets/images/mark.png', width: 40, height: 40, semanticLabel: 'SkinSense'),
              ],
            ),
            if (_status == LoadStatus.error && _profile != null) ...[
              const SizedBox(height: 20),
              NoticeBox(text: 'Profil belum dapat diperbarui. Data terakhir tetap ditampilkan.', onRetry: _fetch),
            ],
            if (_status == LoadStatus.error && _profile == null)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: StateMessage(
                  title: 'Profil belum dapat dimuat',
                  text: 'Periksa koneksi internet Anda, lalu coba lagi.',
                ),
              ),
            if (_status == LoadStatus.error && _profile == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: AppButton(title: 'Coba Lagi', onPressed: () => _fetch(showLoading: true)),
              )
            else ...[
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: complete ? 'Mulai Pemeriksaan' : 'Lengkapi Profil',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => _open(complete ? '/process' : '/profile'),
                  child: Viewfinder(
                    color: complete ? AppColors.teal : AppColors.inkFaint,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.camera,
                              size: 40, color: complete ? AppColors.tealDeep : AppColors.inkFaint),
                          const SizedBox(height: 16),
                          Text(
                            complete ? 'Periksa lesi kulit' : 'Profil belum lengkap',
                            textAlign: TextAlign.center,
                            style: AppText.title.copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            complete
                                ? 'Foto dianalisis langsung di ponsel ini.'
                                : 'Isi nama, jenis kelamin, tanggal lahir, dan nomor telepon terlebih dahulu.',
                            textAlign: TextAlign.center,
                            style: AppText.body.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (complete) ...[
                AppButton(title: 'Mulai Pemeriksaan', onPressed: () => _open('/process')),
                const SizedBox(height: 28),
                Text('Agar hasil akurat', style: AppText.lead.copyWith(color: AppColors.ink)),
                for (final tip in const [
                  'Gunakan cahaya terang tanpa bayangan.',
                  'Dekatkan kamera hingga lesi memenuhi sebagian besar bingkai.',
                  'Tahan ponsel diam sampai gambar tajam.',
                ]) ...[
                  const SizedBox(height: 8),
                  Text(tip, style: AppText.body.copyWith(color: AppColors.inkMuted)),
                ],
              ] else
                AppButton(title: 'Lengkapi Profil', onPressed: () => _open('/profile')),
            ],
          ],
        ),
      ),
    );
  }
}
