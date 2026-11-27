import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skinsense/logic.dart';

const refBinary = 2.4375308;
const refClasses = [-1.1755426, 0.9738036, -4.220344, -4.6698136, 4.3817725, 1.4510419,
  -3.1659076, -0.84482235, -4.475667, 0.43181643];

void main() {
  test('model outputs map to sigmoid risk, softmax over 10 classes and a detected top class', () {
    final p = interpretOutputs(refBinary, refClasses);
    expect(p.cancerDetected, isTrue);
    expect(p.malignantProbability, closeTo(0.91961, 1e-4));
    expect(p.topClass, 'scc_in_situ');
    expect(p.classProbabilities.length, 10);
    expect(p.classProbabilities.values.reduce((a, b) => a + b), closeTo(1, 1e-9));
  });

  test('risk below threshold is not detected and top class comes from the benign group', () {
    final below = interpretOutputs(math.log(0.3 / 0.7), refClasses);
    expect(below.cancerDetected, isFalse);
    expect(below.topClass, 'vascular_lesion');
    expect(interpretOutputs(math.log(0.3151 / 0.6849), refClasses).cancerDetected, isTrue);
  });

  test('invalid model outputs are rejected', () {
    expect(() => interpretOutputs(double.nan, refClasses), throwsArgumentError);
    expect(() => interpretOutputs(0, [1, 2, 3]), throwsArgumentError);
  });

  test('RGBA pixels become an ImageNet-normalized NCHW tensor', () {
    final rgba = Uint8List.fromList([255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 128, 128, 128, 255]);
    final out = rgbaToInputTensor(rgba, 2);
    expect(out.length, 12);
    expect(out[0], closeTo((1 - 0.485) / 0.229, 1e-5));
    expect(out[1], closeTo((0 - 0.485) / 0.229, 1e-5));
    expect(out[5], closeTo((1 - 0.456) / 0.224, 1e-5));
    expect(out[10], closeTo((1 - 0.406) / 0.225, 1e-5));
    expect(() => rgbaToInputTensor(Uint8List(4), 2), throwsArgumentError);
  });

  test('formatters match the original app', () {
    expect(formatConfidence(0.91961), '92%');
    expect(formatConfidence(0.315), '31.5%');
    expect(formatConfidence(1.2), dataNotAvailable);
    expect(formatDiagnosis('cancer_detected'), 'Kanker Kulit Terdeteksi');
    expect(formatDiagnosis('pending'), resultNotAvailable);
    expect(formatDiagnosis('some-new value'), 'Some New Value');
    expect(formatStatus('completed'), 'Selesai');
    expect(getDiagnosisTone('melanoma', 'completed'), DiagnosisTone.danger);
    expect(getDiagnosisTone('not_detected', 'completed'), DiagnosisTone.safe);
    expect(getDiagnosisTone('not_detected', 'pending'), DiagnosisTone.neutral);
  });

  test('profile validation and birth dates', () {
    expect(isValidPhone('0812 3456'), isTrue);
    expect(isValidPhone('12'), isFalse);
    expect(isValidPhone('08a123'), isFalse);
    expect(isValidBirthDate('2024-02-29'), isTrue);
    expect(isValidBirthDate('2023-02-29'), isFalse);
    expect(isAllowedBirthDate('2999-01-01'), isFalse);
    expect(formatBirthDate('2006-02-22'), '22 Februari 2006');
    expect(isProfileComplete({'full_name': 'User', 'phone': '123', 'birth_date': '2000-01-01', 'gender': 'male'}), isTrue);
    expect(isProfileComplete({'full_name': 'User'}), isFalse);
  });

  test('user-facing errors never leak raw messages', () {
    expect(getSafeErrorMessage(Exception('Invalid login credentials'), 'x', auth: true), 'Email atau password salah.');
    expect(getSafeErrorMessage(Exception('SocketException: Failed host lookup'), 'x'),
        'Koneksi bermasalah. Periksa internet lalu coba lagi.');
    expect(
        getSafeErrorMessage(
            Exception('AuthRetryableFetchException(message: ClientException with SocketException: Failed host lookup, '
                'uri=https://x.supabase.co/auth/v1/token?grant_type=password)'),
            'x',
            auth: true),
        'Koneksi bermasalah. Periksa internet lalu coba lagi.');
    expect(getSafeErrorMessage(Exception('Password should be at least 6 characters'), 'x', auth: true),
        'Password tidak memenuhi persyaratan.');
    expect(getSafeErrorMessage(Exception('duplicate key violates constraint'), 'fallback'), 'fallback');
  });
}
