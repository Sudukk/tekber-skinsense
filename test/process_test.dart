import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skinsense/screens/process.dart';
import 'package:skinsense/theme.dart';
import 'package:skinsense/widgets.dart';

void main() {
  testWidgets('ProcessScreen renders scan options and navigates back to /home', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/process',
      routes: [
        GoRoute(path: '/process', builder: (_, _) => const ProcessScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Center(child: Text('Beranda'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: appTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Foto lesi'), findsOneWidget);
    expect(find.byType(Viewfinder), findsOneWidget);
    expect(find.text('Ambil Foto'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Kembali'), 200);
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
  });
}
