import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

const _guideSteps = [
  ('Lengkapi profil',
      'Isi nama, jenis kelamin, tanggal lahir, dan nomor telepon. Setelah itu tekan Mulai Pemeriksaan di menu Periksa.'),
  ('Foto lesi',
      'Tekan Ambil Foto dan potret lesi dari jarak dekat dengan cahaya terang, atau pilih foto dari galeri. Pastikan lesi berada di tengah dan tidak buram.'),
  ('Tunggu analisis',
      'Foto dianalisis langsung di ponsel oleh model kecerdasan buatan untuk 10 jenis lesi kulit, tanpa perangkat tambahan.'),
  ('Baca hasil',
      'Aplikasi menampilkan kesimpulan (kanker kulit terdeteksi atau tidak), skor risiko, dan probabilitas setiap kelas lesi.'),
  ('Buka lagi kapan saja',
      'Semua hasil tersimpan di menu Riwayat dan dapat diunduh sebagai PDF atau dikirim lewat email.'),
];

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            screenTitle('Panduan', 'Lima langkah dari foto sampai hasil.', bottom: 24),
            for (final (index, (title, body)) in _guideSteps.indexed)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.tealWash, shape: BoxShape.circle),
                            child: Text('${index + 1}',
                                style: AppText.button.copyWith(fontSize: 15, color: AppColors.tealDeep)),
                          ),
                          if (index < _guideSteps.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: AppColors.line,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppText.lead.copyWith(color: AppColors.ink)),
                            const SizedBox(height: 4),
                            Text(body, style: AppText.body.copyWith(color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'SkinSense membantu pemeriksaan awal dan tidak menggantikan dokter. Periksakan lesi '
              'yang berubah ukuran, bentuk, atau warna, terasa gatal, atau berdarah.',
              style: AppText.caption.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      );
}
