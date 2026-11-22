import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'logic.dart';
import 'theme.dart';

enum ButtonVariant { primary, secondary, quiet, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
    this.icon,
  });

  final String title;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool disabled;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (variant) {
      ButtonVariant.primary => (AppColors.teal, AppColors.paper, null),
      ButtonVariant.secondary => (AppColors.paper, AppColors.ink, AppColors.ink),
      ButtonVariant.quiet => (Colors.transparent, AppColors.tealDeep, null),
      ButtonVariant.danger => (AppColors.paper, AppColors.danger, AppColors.line),
    };
    final text = Text(
      title,
      textAlign: TextAlign.center,
      style: AppText.button.copyWith(color: foreground),
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          splashColor: variant == ButtonVariant.primary ? AppColors.tealDeep : AppColors.tealWash,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: icon == null
                  ? Center(child: text)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [icon!, const SizedBox(width: 10), Flexible(child: text)],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _boxDecoration({String? hint, Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: AppText.input.copyWith(color: AppColors.inkFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.paper,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    );

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: AppText.label),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.autofillHints,
    this.obscure = false,
    this.onToggleVisible,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final VoidCallback? onToggleVisible;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) => LabeledField(
        label: label,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: onToggleVisible == null && keyboardType != TextInputType.emailAddress,
          textCapitalization: capitalization,
          style: AppText.input,
          decoration: _boxDecoration(
            hint: hint,
            suffix: onToggleVisible == null
                ? null
                : IconButton(
                    onPressed: onToggleVisible,
                    tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
                    icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20, color: AppColors.inkMuted),
                  ),
          ),
        ),
      );
}

class GenderField extends StatelessWidget {
  const GenderField({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LabeledField(
        label: 'Jenis Kelamin',
        child: DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: (next) => onChanged(next ?? ''),
          style: AppText.input,
          iconEnabledColor: AppColors.ink,
          dropdownColor: AppColors.paper,
          decoration: _boxDecoration(),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text('Pilih jenis kelamin', style: AppText.input.copyWith(color: AppColors.inkFaint)),
            ),
            const DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
            const DropdownMenuItem(value: 'female', child: Text('Perempuan')),
          ],
        ),
      );
}

class BirthDateField extends StatelessWidget {
  const BirthDateField({super.key, required this.value, required this.onChanged, this.disabled = false});
  final String value;
  final ValueChanged<String> onChanged;
  final bool disabled;

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final selected = isAllowedBirthDate(value, today) ? parseCalendarDate(value) ?? today : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(1900),
      lastDate: today,
      confirmText: 'OK',
      cancelText: 'Batal',
      helpText: 'Tanggal Lahir',
    );
    if (picked == null) return;
    final next = serializeCalendarDate(picked);
    if (isAllowedBirthDate(next)) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final display = formatBirthDate(value);
    return LabeledField(
      label: 'Tanggal Lahir',
      child: Semantics(
        button: true,
        label: 'Tanggal Lahir, ${display.isEmpty ? 'belum dipilih' : display}',
        hint: 'Buka kalender untuk memilih tanggal lahir',
        excludeSemantics: true,
        child: InkWell(
          onTap: disabled ? null : () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display.isEmpty ? 'Pilih tanggal lahir' : display,
                    style: AppText.input.copyWith(color: display.isEmpty ? AppColors.inkFaint : AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.calendarDays, size: 22, color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
