import 'package:flutter/material.dart';

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