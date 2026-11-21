import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logic.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

bool _isValidEmail(String value) => RegExp(r'\S+@\S+\.\S+').hasMatch(value);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final spacing = (constraints.maxHeight * 0.035 / MediaQuery.textScalerOf(context).scale(1))
                  .clamp(12.0, 24.0);
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 432, minHeight: constraints.maxHeight - 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: (constraints.maxHeight * 0.45).clamp(0, 300)),
                            child: AspectRatio(
                              aspectRatio: 1.2,
                              child: ClipRect(
                                child: OverflowBox(
                                  maxHeight: double.infinity,
                                  child: Image.asset('assets/images/Logo.png', semanticLabel: 'SkinSense'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              'Foto lesi kulit dengan kamera ponsel. Analisis berjalan langsung di ponsel, '
                              'dan setiap hasil tersimpan di riwayat Anda.',
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(fontSize: 16, height: 1.5, color: AppColors.inkMuted),
                            ),
                          ),
                        ),
                        SizedBox(height: spacing + 12),
                        AppButton(title: 'Daftar', onPressed: () => context.push('/register')),
                        const SizedBox(height: 12),
                        AppButton(
                          title: 'Masuk',
                          variant: ButtonVariant.secondary,
                          onPressed: () => context.push('/login'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}