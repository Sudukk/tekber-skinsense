import 'package:flutter/material.dart';

// Issue #5 memakai AppColors dan AppText dari theme.dart (Issue #3).
import 'theme.dart';

// StateMessage dan NoticeBox memakai AppButton dan ButtonVariant dari Issue #4.

class Viewfinder extends StatelessWidget {
  const Viewfinder({super.key, required this.child, this.color = AppColors.teal, this.background = AppColors.skin});
  final Widget child;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(
                color: background,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    IgnorePointer(child: CustomPaint(painter: _CornersPainter(color))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);
  final Color color;

  static const _arm = 28.0;
  static const _inset = 10.0;
  static const _stroke = 4.0;
  static const _radius = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    const o = _inset + _stroke / 2;
    const r = _radius - _stroke / 2;
    const l = _arm - _stroke / 2;

    Path corner() => Path()
      ..moveTo(o, o + l)
      ..lineTo(o, o + r)
      ..arcToPoint(const Offset(o + r, o), radius: const Radius.circular(r))
      ..lineTo(o + l, o);

    for (final (sx, sy) in const [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      canvas.save();
      canvas.translate(sx < 0 ? size.width : 0, sy < 0 ? size.height : 0);
      canvas.scale(sx, sy);
      canvas.drawPath(corner(), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => oldDelegate.color != color;
}

class FormScreen extends StatelessWidget {
  const FormScreen({super.key, required this.children, this.center = false, this.bottomInset = true});
  final List<Widget> children;
  final bool center;
  final bool bottomInset;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: bottomInset,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 432, minHeight: constraints.maxHeight - 48),
                  child: Column(
                    mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class StateMessage extends StatelessWidget {
  const StateMessage({super.key, required this.title, this.text, this.actionTitle, this.onAction, this.loading = false});
  final String title;
  final String? text;
  final String? actionTitle;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
              ],
              Text(title,
                  textAlign: TextAlign.center,
                  style: loading
                      ? AppText.body.copyWith(color: AppColors.inkMuted)
                      : AppText.lead.copyWith(color: AppColors.ink)),
              if (text != null) ...[
                const SizedBox(height: 8),
                Text(text!, textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.inkMuted)),
              ],
              if (actionTitle != null) ...[
                const SizedBox(height: 24),
                AppButton(title: actionTitle!, onPressed: onAction),
              ],
            ],
          ),
        ),
      );
}

class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.text, this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.fromLTRB(16, 14, 16, onRetry == null ? 14 : 4),
        decoration: BoxDecoration(color: AppColors.warningWash, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: AppText.body.copyWith(color: AppColors.warning)),
            if (onRetry != null) AppButton(title: 'Coba Lagi', variant: ButtonVariant.quiet, onPressed: onRetry),
          ],
        ),
      );
}

Future<bool?> showAlert(
  BuildContext context,
  String title,
  String message, {
  String okText = 'OK',
  String? cancelText,
  bool destructive = false,
}) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppText.lead.copyWith(color: AppColors.ink)),
        content: Text(message, style: AppText.body.copyWith(color: AppColors.inkMuted)),
        actions: [
          if (cancelText != null)
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.danger) : null,
            child: Text(okText),
          ),
        ],
      ),
    );

Widget screenTitle(String title, String subtitle, {double bottom = 20}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: AppText.display.copyWith(color: AppColors.ink))),
        const SizedBox(height: 6),
        Text(subtitle, style: AppText.body.copyWith(color: AppColors.inkMuted)),
        SizedBox(height: bottom),
      ],
    );
