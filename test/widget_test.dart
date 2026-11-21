import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:skinsense/main.dart';
import 'package:skinsense/services.dart';

void main() {
  testWidgets('HomeScreen displays complete profile state and nav bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    setLocalProfileForTesting({
      'full_name': 'Demo',
      'gender': 'male',
      'birth_date': '2000-01-01',
      'phone': '08123456789',
    });

    await tester.pumpWidget(const SkinSenseApp());
    await tester.pumpAndSettle();

    expect(find.text('Halo,'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Periksa lesi kulit'), findsOneWidget);
    expect(find.text('Foto dianalisis langsung di ponsel ini.'), findsOneWidget);
    expect(find.text('Mulai Pemeriksaan'), findsOneWidget);
    expect(find.text('Agar hasil akurat'), findsOneWidget);
    expect(find.text('Gunakan cahaya terang tanpa bayangan.'), findsOneWidget);
    expect(find.text('Dekatkan kamera hingga lesi memenuhi sebagian besar bingkai.'), findsOneWidget);
    expect(find.text('Tahan ponsel diam sampai gambar tajam.'), findsOneWidget);
    expect(find.text('Lengkapi Profil'), findsNothing);

    expect(find.text('Periksa'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Panduan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('HomeScreen shows Lengkapi Profil when profile is incomplete', (WidgetTester tester) async {
    setLocalProfileForTesting({
      'full_name': 'Demo',
      'gender': '',
      'birth_date': '',
      'phone': '',
    });

    await tester.pumpWidget(const SkinSenseApp());
    await tester.pumpAndSettle();

    expect(find.text('Profil belum lengkap'), findsOneWidget);
    expect(find.text('Lengkapi Profil'), findsOneWidget);
    expect(find.text('Mulai Pemeriksaan'), findsNothing);
  });

  testWidgets('GuideScreen displays five usage steps', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SkinSenseApp(initialLocation: '/guide'));
    await tester.pumpAndSettle();

    expect(find.text('Lima langkah dari foto sampai hasil.'), findsOneWidget);
    expect(find.text('Lengkapi profil'), findsOneWidget);
    expect(find.text('Foto lesi'), findsOneWidget);
    expect(find.text('Tunggu analisis'), findsOneWidget);
    expect(find.text('Baca hasil'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Buka lagi kapan saja'), 200);
    expect(find.text('Buka lagi kapan saja'), findsOneWidget);
  });
}
