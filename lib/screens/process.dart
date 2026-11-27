import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../logic.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

enum _Phase { idle, analyzing, saving, error }

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});
  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  _Phase _phase = _Phase.idle;
  String? _photoPath;
  String? _error;
  SkinPrediction? _prediction;

  void _fail(String message) => setState(() {
        _error = message;
        _phase = _Phase.error;
      });

  Future<void> _save(String path, SkinPrediction result) async {
    setState(() => _phase = _Phase.saving);
    try {
      final scanId = await saveScanResult(await prepareUploadImage(path), result);
      if (mounted) context.pushReplacement('/history/$scanId');
    } catch (failure) {
      debugPrint('Gagal menyimpan hasil pemeriksaan: $failure');
      if (mounted) _fail('Hasil analisis belum tersimpan. Periksa koneksi internet lalu coba lagi.');
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    final String? path;
    try {
      final picked = await ImagePicker().pickImage(source: source, requestFullMetadata: false);
      if (picked == null) return;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong foto',
            toolbarColor: AppColors.paper,
            toolbarWidgetColor: AppColors.ink,
            activeControlsWidgetColor: AppColors.teal,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(title: 'Potong foto', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
        ],
      );
      path = cropped?.path;
    } on PlatformException catch (failure) {
      if (failure.code.contains('access_denied')) {
        _fail(source == ImageSource.camera
            ? 'Izin kamera diperlukan untuk memotret lesi.'
            : 'Izin galeri diperlukan untuk memilih foto.');
      } else {
        _fail('Foto tidak dapat dibuka. Silakan coba lagi.');
      }
      return;
    }
    if (path == null || !mounted) return;

    setState(() {
      _photoPath = path;
      _prediction = null;
      _phase = _Phase.analyzing;
    });

    final SkinPrediction result;
    try {
      result = await classifySkinImage(path);
    } catch (failure) {
      debugPrint('Inferensi on-device gagal: $failure');
      if (mounted) _fail('Foto tidak dapat dianalisis. Silakan ambil foto lain.');
      return;
    }
    if (!mounted) return;
    setState(() => _prediction = result);
    await _save(path, result);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _phase == _Phase.analyzing || _phase == _Phase.saving;
    final canRetrySave = _phase == _Phase.error && _photoPath != null && _prediction != null;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          screenTitle(
            'Foto lesi',
            _photoPath != null
                ? 'Foto yang sedang diperiksa.'
                : 'Potret dari jarak dekat dengan cahaya terang. Pastikan lesi berada di tengah dan tidak buram.',
          ),
          Viewfinder(
            color: _error != null ? AppColors.danger : AppColors.teal,
            child: _photoPath != null
                ? Image.file(File(_photoPath!), fit: BoxFit.cover, semanticLabel: 'Foto lesi yang diperiksa')
                : Center(
                    child: Transform.rotate(
                      angle: -12 * 3.1415926535 / 180,
                      child: Container(
                        width: 64,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.skinDeep,
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
          ),
          if (busy)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _phase == _Phase.analyzing
                              ? 'Menganalisis foto di ponsel...'
                              : 'Menyimpan hasil pemeriksaan...',
                          style: AppText.lead.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 20),
            if (_error != null) ...[
              Semantics(liveRegion: true, child: Text(_error!, style: AppText.body.copyWith(color: AppColors.danger))),
              const SizedBox(height: 12),
            ],
            if (canRetrySave) ...[
              AppButton(title: 'Coba Simpan Lagi', onPressed: () => _save(_photoPath!, _prediction!)),
              const SizedBox(height: 12),
            ],
            AppButton(
              title: 'Ambil Foto',
              variant: canRetrySave ? ButtonVariant.secondary : ButtonVariant.primary,
              onPressed: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            AppButton(
              title: 'Pilih dari Galeri',
              variant: ButtonVariant.secondary,
              onPressed: () => _pick(ImageSource.gallery),
            ),
          ],
          const SizedBox(height: 8),
          AppButton(
            title: 'Kembali',
            variant: ButtonVariant.quiet,
            disabled: busy,
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
        ],
      ),
    );
  }
}
