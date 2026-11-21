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

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submitTitle,
    required this.loading,
    required this.onSubmit,
    required this.onOAuth,
    required this.message,
    required this.error,
    required this.footerText,
    required this.footerLink,
    required this.footerRoute,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String submitTitle;
  final bool loading;
  final VoidCallback onSubmit;
  final void Function(OAuthProvider) onOAuth;
  final String message;
  final String error;
  final String footerText;
  final String footerLink;
  final String footerRoute;

  @override
  Widget build(BuildContext context) => FormScreen(
        center: true,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/images/mark.png', width: 44, height: 44, excludeFromSemantics: true),
          ),
          const SizedBox(height: 20),
          screenTitle(title, subtitle, bottom: 28),
          ...fields,
          const SizedBox(height: 8),
          AppButton(title: loading ? 'Memproses...' : submitTitle, disabled: loading, onPressed: onSubmit),
          if (showSocialAuth) ...[
            const SizedBox(height: 10),
            AppButton(
              title: 'Masuk dengan Google',
              variant: ButtonVariant.secondary,
              disabled: loading,
              onPressed: () => onOAuth(OAuthProvider.google),
            ),
            const SizedBox(height: 10),
            AppButton(
              title: 'Masuk dengan Apple',
              variant: ButtonVariant.secondary,
              disabled: loading,
              onPressed: () => onOAuth(OAuthProvider.apple),
            ),
          ],
          if (message.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(message, style: AppText.caption.copyWith(color: AppColors.tealDeep)),
          ],
          if (error.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Text(error, style: AppText.caption.copyWith(color: AppColors.danger)),
            ),
          ],
          const SizedBox(height: 28),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(footerText, style: AppText.body.copyWith(color: AppColors.inkMuted)),
              InkWell(
                onTap: () => context.pushReplacement(footerRoute),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text(
                    footerLink,
                    style: AppText.button.copyWith(fontSize: 15, color: AppColors.tealDeep),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

abstract class _AuthState<T extends StatefulWidget> extends State<T> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;
  bool loading = false;
  String message = '';
  String error = '';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void toggleVisible() => setState(() => showPassword = !showPassword);

  Future<void> run(String progress, String fallback, Future<void> Function() action) async {
    setState(() {
      loading = true;
      message = progress;
      error = '';
    });
    try {
      ensureSupabaseConfigured();
      await action();
    } catch (failure) {
      debugPrint('Autentikasi gagal: $failure');
      if (mounted) {
        setState(() {
          message = '';
          error = getSafeErrorMessage(failure, fallback, auth: true);
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void fail(String text) => setState(() {
        message = '';
        error = text;
      });

  Future<void> oauth(OAuthProvider provider) => run(
        provider == OAuthProvider.google ? 'Membuka login Google...' : 'Membuka login Apple...',
        'Login sosial gagal. Silakan coba lagi.',
        () async {
          final launched = await supabase.auth.signInWithOAuth(
            provider,
            redirectTo: oauthRedirectUrl,
            authScreenLaunchMode: LaunchMode.externalApplication,
          );
          if (!launched) throw Exception('Login dibatalkan.');
        },
      );
}
