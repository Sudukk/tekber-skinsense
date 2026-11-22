import 'dart:math' as math;
import 'dart:typed_data';

const modelVersion = 'mobileone_s4_distilled_skin10_v1';
const modelInputSize = 256;
const cancerThreshold = 0.315;

class SkinClass {
  const SkinClass(this.code, this.label, this.malignant);
  final String code;
  final String label;
  final bool malignant;
}

const skinClasses = [
  SkinClass('melanoma_invasive', 'Melanoma Invasif', true),
  SkinClass('melanoma_in_situ', 'Melanoma In Situ', true),
  SkinClass('basal_cell_carcinoma', 'Karsinoma Sel Basal', true),
  SkinClass('scc_invasive', 'Karsinoma Sel Skuamosa Invasif', true),
  SkinClass('scc_in_situ', 'Karsinoma Sel Skuamosa In Situ', true),
  SkinClass('actinic_keratosis', 'Keratosis Aktinik', true),
  SkinClass('melanocytic_nevus', 'Nevus Melanositik (Tahi Lalat)', false),
  SkinClass('benign_keratosis', 'Keratosis Jinak', false),
  SkinClass('dermatofibroma', 'Dermatofibroma', false),
  SkinClass('vascular_lesion', 'Lesi Vaskular', false),
];

SkinClass? getSkinClass(String? code) {
  for (final cls in skinClasses) {
    if (cls.code == code) return cls;
  }
  return null;
}

class SkinPrediction {
  const SkinPrediction({
    required this.cancerDetected,
    required this.malignantProbability,
    required this.topClass,
    required this.classProbabilities,
  });
  final bool cancerDetected;
  final double malignantProbability;
  final String topClass;
  final Map<String, double> classProbabilities;
}

const _mean = [0.485, 0.456, 0.406];
const _std = [0.229, 0.224, 0.225];

Float32List rgbaToInputTensor(Uint8List rgba, [int size = modelInputSize]) {
  final plane = size * size;
  if (rgba.length < plane * 4) {
    throw ArgumentError('Ukuran gambar tidak sesuai input model.');
  }
  final out = Float32List(plane * 3);
  for (var i = 0; i < plane; i++) {
    for (var c = 0; c < 3; c++) {
      out[c * plane + i] = (rgba[i * 4 + c] / 255 - _mean[c]) / _std[c];
    }
  }
  return out;
}

SkinPrediction interpretOutputs(double binaryLogit, List<double> classLogits) {
  if (classLogits.length != skinClasses.length || !binaryLogit.isFinite) {
    throw ArgumentError('Output model tidak valid.');
  }
  final malignantProbability = 1 / (1 + math.exp(-binaryLogit));
  final max = classLogits.reduce(math.max);
  final exps = [for (final v in classLogits) math.exp(v - max)];
  final sum = exps.reduce((a, b) => a + b);
  final cancerDetected = malignantProbability >= cancerThreshold;

  final classProbabilities = <String, double>{};
  var topIndex = -1;
  for (var i = 0; i < skinClasses.length; i++) {
    classProbabilities[skinClasses[i].code] = exps[i] / sum;
    if (skinClasses[i].malignant == cancerDetected &&
        (topIndex < 0 || exps[i] > exps[topIndex])) {
      topIndex = i;
    }
  }

  return SkinPrediction(
    cancerDetected: cancerDetected,
    malignantProbability: malignantProbability,
    topClass: skinClasses[topIndex].code,
    classProbabilities: classProbabilities,
  );
}

const dataNotAvailable = 'Data tidak tersedia';
const resultNotAvailable = 'Hasil belum tersedia';

String formatConfidence(num? value) {
  if (value == null || !value.isFinite || value < 0 || value > 1) {
    return dataNotAvailable;
  }
  final percent = double.parse((value * 100).toStringAsFixed(1));
  return '${percent == percent.roundToDouble() ? percent.toInt() : percent}%';
}

String normalizeResultValue(String? value) =>
    value == null ? '' : value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

const _unavailableValues = {
  '', 'null', 'undefined', 'nan', 'infinity', '_infinity',
  'unknown', 'unavailable', 'data_tidak_tersedia', 'tingkat_keyakinan',
};

const _resultLabels = {
  'cancer_detected': 'Kanker Kulit Terdeteksi',
  'not_detected': 'Kanker Kulit Tidak Terdeteksi',
  'non_melanoma': 'Non Melanoma',
  'nonmelanoma': 'Non Melanoma',
  'melanoma': 'Melanoma',
  'risk_detected': 'Risiko Terdeteksi',
  'low_risk': 'Risiko Rendah',
  'high_risk': 'Risiko Tinggi',
  'high_severity': 'Risiko Tinggi',
};

String _humanizeLabel(String value) => value
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

String formatDiagnosis(String? value) {
  final normalized = normalizeResultValue(value);
  if (_unavailableValues.contains(normalized) ||
      const ['pending', 'processing', 'queued'].contains(normalized)) {
    return resultNotAvailable;
  }
  return _resultLabels[normalized] ?? _humanizeLabel(normalized);
}

String formatStatus(String? value) {
  final normalized = normalizeResultValue(value);
  if (_unavailableValues.contains(normalized)) return dataNotAvailable;
  const statusLabels = {
    'completed': 'Selesai',
    'pending': 'Diproses',
    'processing': 'Diproses',
    'queued': 'Dalam Antrean',
  };
  return statusLabels[normalized] ?? _resultLabels[normalized] ?? _humanizeLabel(normalized);
}

enum DiagnosisTone { safe, danger, neutral }

const detectedValues = ['cancer_detected', 'melanoma', 'risk_detected', 'high_risk', 'high_severity'];
const notDetectedValues = ['not_detected', 'non_melanoma', 'nonmelanoma'];
const _pendingValues = ['pending', 'processing', 'queued', 'unknown'];

DiagnosisTone getDiagnosisTone(String? diagnosis, String? status) {
  final d = normalizeResultValue(diagnosis);
  final s = normalizeResultValue(status);
  if (_pendingValues.contains(d) || _pendingValues.contains(s)) {
    return DiagnosisTone.neutral;
  }
  if (detectedValues.contains(d) ||
      const ['risk_detected', 'high_risk', 'high_severity', 'critical'].contains(s)) {
    return DiagnosisTone.danger;
  }
  return notDetectedValues.contains(d) ? DiagnosisTone.safe : DiagnosisTone.neutral;
}

String getRecommendation(String? diagnosis) {
  final normalized = normalizeResultValue(diagnosis);
  if (detectedValues.contains(normalized)) {
    return 'Segera konsultasikan lesi ini ke dokter spesialis kulit untuk '
        'pemeriksaan dermoskopi dan, bila perlu, biopsi.';
  }
  if (notDetectedValues.contains(normalized)) {
    return 'Tidak ditemukan indikasi kanker kulit. Tetap pantau lesi dan periksakan '
        'ke dokter bila ukuran, bentuk, atau warnanya berubah, gatal, atau berdarah.';
  }
  return dataNotAvailable;
}

String normalizeText(String? value) => value?.trim() ?? '';

String normalizePhone(String? value) => normalizeText(value).replaceAll(RegExp(r'\s+'), ' ');

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
