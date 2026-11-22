import 'dart:developer';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

const _genderLabels = {'male': 'Laki-laki', 'female': 'Perempuan'};

enum LoadStatus { loading, success, error, incomplete }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  LoadStatus _status = LoadStatus.loading;
  bool _loggingOut = false;
  bool _dialogOpen = false;
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
        _status = isProfileComplete(profile)
            ? LoadStatus.success
            : LoadStatus.incomplete;
      });
    } catch (_) {
      if (mounted) setState(() => _status = LoadStatus.error);
    }
  })().whenComplete(() => _inFlight = null);

  Future<void> _confirmLogout() async {
    if (_dialogOpen || _loggingOut) return;
    _dialogOpen = true;
    final confirmed = await showAlert(
      context,
      'Log Out',
      'Anda yakin ingin keluar dari akun ini?',
      okText: 'Log Out',
      cancelText: 'Batal',
      destructive: true,
    );
    _dialogOpen = false;
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      ensureSupabaseConfigured();
      await supabase.auth.signOut();
      // TODO: redirect ke login page go router.
    } catch (failure) {
      log('$failure');
      if (mounted) {
        await showAlert(
          context,
          'Log Out gagal',
          getSafeErrorMessage(
            failure,
            'Terjadi kesalahan saat keluar. Silakan coba lagi.',
            auth: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Widget _item(String label, String? value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption.copyWith(color: AppColors.inkMuted)),
        const SizedBox(height: 2),
        Text(
          value == null || value.trim().isEmpty ? '-' : value,
          style: AppText.label.copyWith(fontSize: 16, height: 22 / 16),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_status == LoadStatus.loading && _profile == null) {
      return const StateMessage(title: 'Memuat profil...', loading: true);
    }
    if (_status == LoadStatus.error && _profile == null) {
      return StateMessage(
        title: 'Profil belum dapat dimuat',
        text: 'Periksa koneksi internet Anda, lalu coba lagi.',
        actionTitle: 'Coba Lagi',
        onAction: () => _fetch(showLoading: true),
      );
    }

    final user = supabase.auth.currentUser;
    final metadataName = user?.userMetadata?['name'];
    final gender = _profile?['gender'] as String?;
    final birthDate = _profile?['birth_date'] as String?;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            screenTitle(
              'Profil',
              'Data ini dipakai untuk laporan hasil pemeriksaan.',
            ),
            if (_status == LoadStatus.error)
              NoticeBox(
                text: 'Profil belum dapat diperbarui. Data terakhir tetap ditampilkan.',
                onRetry: _fetch,
              ),
            if (_status == LoadStatus.incomplete)
              const NoticeBox(
                text: 'Profil belum lengkap. Lengkapi empat data wajib agar dapat memulai pemeriksaan.',
              ),
            const Divider(height: 0.5, thickness: 0.5, color: AppColors.line),
            _item(
              'Nama',
              _profile?['full_name'] as String? ??
                  (metadataName is String ? metadataName : '-'),
            ),
            _item(
              'Jenis Kelamin',
              gender == null ? null : _genderLabels[gender] ?? gender,
            ),
            _item(
              'Tanggal Lahir',
              birthDate == null ? null : formatBirthDate(birthDate),
            ),
            _item('Nomor Telepon', _profile?['phone'] as String?),
            _item('Email', user?.email),
            const SizedBox(height: 28),
            AppButton(
              title: 'Edit Profil',
              variant: ButtonVariant.secondary,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                if (mounted) _fetch();
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              title: _loggingOut ? 'Keluar...' : 'Log Out',
              variant: ButtonVariant.danger,
              disabled: _loggingOut,
              onPressed: _confirmLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _birthDate = '';
  String _gender = '';
  LoadStatus _status = LoadStatus.loading;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final profile = await getCurrentUserProfile();
      if (!mounted) return;
      final gender = profile['gender'];
      setState(() {
        _name.text = profile['full_name'] as String? ?? '';
        _birthDate = profile['birth_date'] as String? ?? '';
        _phone.text = profile['phone'] as String? ?? '';
        _gender = gender == 'male' || gender == 'female'
            ? gender as String
            : '';
        _status = LoadStatus.success;
      });
    } catch (_) {
      if (mounted) setState(() => _status = LoadStatus.error);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      await showAlert(context, 'Data belum lengkap', 'Nama wajib diisi.');
      return;
    }
    if (_gender.isEmpty) {
      await showAlert(context, 'Data belum lengkap', 'Pilih jenis kelamin.');
      return;
    }
    if (!isAllowedBirthDate(_birthDate)) {
      await showAlert(
        context,
        'Tanggal lahir tidak valid',
        'Pilih tanggal lahir yang benar dan tidak di masa depan.',
      );
      return;
    }
    if (!isValidPhone(_phone.text)) {
      await showAlert(
        context,
        'Nomor telepon tidak valid',
        'Nomor telepon wajib diisi dengan angka yang valid.',
      );
      return;
    }

    setState(() => _saving = true);
    Object? error;
    try {
      await updateCurrentUserProfile(
        fullName: _name.text.trim(),
        gender: _gender,
        birthDate: _birthDate.trim(),
        phone: normalizePhone(_phone.text),
      );
    } catch (failure) {
      error = failure;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    if (error != null) {
      await showAlert(
        context,
        'Gagal menyimpan profil',
        getSafeErrorMessage(
          error,
          'Profil belum dapat disimpan. Silakan coba lagi.',
        ),
      );
      return;
    }
    await showAlert(context, 'Berhasil', 'Profil berhasil diperbarui.');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == LoadStatus.loading) {
      return const SafeArea(
        child: StateMessage(title: 'Memuat profil...', loading: true),
      );
    }
    if (_status == LoadStatus.error) {
      return SafeArea(
        child: StateMessage(
          title: 'Profil belum dapat dimuat',
          text: 'Periksa koneksi internet Anda, lalu coba lagi.',
          actionTitle: 'Coba Lagi',
          onAction: () {
            setState(() => _status = LoadStatus.loading);
            _fetch();
          },
        ),
      );
    }

    return FormScreen(
      bottomInset: false,
      children: [
        screenTitle(
          'Edit Profil',
          'Keempat data ini wajib diisi sebelum memulai pemeriksaan.',
          bottom: 28,
        ),
        AppField(
          label: 'Nama',
          controller: _name,
          hint: 'Nama lengkap',
          autofillHints: const [AutofillHints.name],
          capitalization: TextCapitalization.words,
        ),
        GenderField(
          value: _gender,
          onChanged: (value) => setState(() => _gender = value),
        ),
        BirthDateField(
          value: _birthDate,
          disabled: _saving,
          onChanged: (value) => setState(() => _birthDate = value),
        ),
        AppField(
          label: 'Nomor Telepon',
          controller: _phone,
          hint: '08xxxxxxxxxx',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: 10),
        AppButton(
          title: _saving ? 'Menyimpan...' : 'Simpan Profil',
          disabled: _saving,
          onPressed: _save,
        ),
        const SizedBox(height: 6),
        AppButton(
          title: 'Batal',
          variant: ButtonVariant.quiet,
          disabled: _saving,
          onPressed: () => Navigator.of( context ).pop(),
        ),
      ],
    );
  }
}
