String normalizeText(String? value) => value?.trim() ?? '';

String normalizePhone(String? value) =>
    normalizeText(value).replaceAll(RegExp(r'\s+'), ' ');

bool isValidPhone(String? value) {
  final normalized = normalizePhone(value);
  final digitCount = RegExp(r'\d').allMatches(normalized).length;
  return normalized.isNotEmpty &&
      digitCount >= 3 &&
      RegExp(r'^[\d+().\-\s]+$').hasMatch(normalized);
}

bool isValidBirthDate(String? value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$')
      .firstMatch(normalizeText(value));
  if (match == null) return false;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  if (year < 1 || month < 1 || month > 12 || day < 1) return false;
  final leapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  final daysInMonth = [
    31,
    leapYear ? 29 : 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];
  return day <= daysInMonth[month - 1];
}

bool isProfileComplete(Map<String, dynamic>? profile) =>
    profile != null &&
    normalizeText(profile['full_name'] as String?).isNotEmpty &&
    isValidPhone(profile['phone'] as String?) &&
    isValidBirthDate(profile['birth_date'] as String?) &&
    normalizeText(profile['gender'] as String?).isNotEmpty;

const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

DateTime? parseCalendarDate(String value) {
  if (!isValidBirthDate(value)) return null;
  final parts = value.trim().split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2], 12);
}

String serializeCalendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool isAllowedBirthDate(String value, [DateTime? today]) =>
    isValidBirthDate(value) &&
    value.trim().compareTo(serializeCalendarDate(today ?? DateTime.now())) <= 0;

String formatBirthDate(String value) {
  if (!isValidBirthDate(value)) return '';
  final parts = value.trim().split('-').map(int.parse).toList();
  return '${parts[2]} ${_months[parts[1] - 1]} ${parts[0].toString().padLeft(4, '0')}';
}

String getSafeErrorMessage(
  Object? error,
  String fallback, {
  bool auth = false,
}) {
  final message = _errorText(error).toLowerCase();

  if (const [
    'network',
    'fetch',
    'socket',
    'host lookup',
    'connection',
  ].any(message.contains)) {
    return 'Koneksi bermasalah. Periksa internet lalu coba lagi.';
  }

  if (auth) {
    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Periksa inbox Anda.';
    }
    if (message.contains('user already registered')) {
      return 'Email tersebut sudah terdaftar.';
    }
    if (message.contains('password')) {
      return 'Password tidak memenuhi persyaratan.';
    }
  }

  return fallback;
}

String _errorText(Object? error) {
  if (error == null) return '';
  try {
    final message = (error as dynamic).message;
    if (message is String) return message;
  } catch (_) {}
  return error.toString();
}
