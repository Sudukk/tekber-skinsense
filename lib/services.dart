import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'logic.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANONYMOUS_KEY');
const supabaseKey = _anonKey != '' ? _anonKey : String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const isSupabaseConfigured = supabaseUrl != '' && supabaseKey != '';
const oauthRedirectUrl = 'melanosense://auth/callback';
const showSocialAuth = false;

const _scanImagesBucket = 'scan-images';

SupabaseClient get supabase => Supabase.instance.client;

void ensureSupabaseConfigured() {
  if (!isSupabaseConfigured) {
    throw Exception('Supabase belum dikonfigurasi. Isi konfigurasi Supabase pada environment aplikasi.');
  }
}

User _requireUser() {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('User belum login.');
  return user;
}

Future<Map<String, dynamic>> getCurrentUserProfile() async {
  final user = _requireUser();
  return supabase.from('profiles').select().eq('id', user.id).single();
}

Future<void> updateCurrentUserProfile({
  required String fullName,
  required String gender,
  required String birthDate,
  required String phone,
}) async {
  final user = _requireUser();
  await supabase
      .from('profiles')
      .update({
        'full_name': fullName,
        'gender': gender,
        'birth_date': birthDate,
        'phone': phone,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', user.id)
      .select()
      .single();
}

Future<String> saveScanResult(Uint8List imageBytes, SkinPrediction prediction) async {
  final user = _requireUser();
  final imagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final bucket = supabase.storage.from(_scanImagesBucket);
  await bucket.uploadBinary(imagePath, imageBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

  try {
    final row = await supabase
        .from('scans')
        .insert({
          'user_id': user.id,
          'image_url': imagePath,
          'status': 'completed',
          'diagnosis': prediction.cancerDetected ? 'cancer_detected' : 'not_detected',
          'malignant_probability': prediction.malignantProbability,
          'top_class': prediction.topClass,
          'class_probabilities': prediction.classProbabilities,
          'model_version': modelVersion,
        })
        .select('id')
        .single();
    return row['id'] as String;
  } catch (_) {
    await bucket.remove([imagePath]).catchError((_) => <FileObject>[]);
    rethrow;
  }
}

Future<OrtSession>? _session;

Future<OrtSession> _getSession() => _session ??= OnnxRuntime()
        .createSessionFromAsset('assets/models/skin10_mobileone.onnx')
        .catchError((Object error) {
      _session = null;
      throw error;
    });

img.Image _decode(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) throw Exception('Foto tidak dapat dibaca.');
  return img.bakeOrientation(image);
}

Float32List _prepareTensor(Uint8List bytes) {
  final resized = img.copyResize(
    _decode(bytes),
    width: modelInputSize,
    height: modelInputSize,
    interpolation: img.Interpolation.linear,
  );
  return rgbaToInputTensor(resized.getBytes(order: img.ChannelOrder.rgba));
}

Uint8List _prepareUpload(Uint8List bytes) => img.encodeJpg(
      img.copyResize(_decode(bytes), width: 1024, interpolation: img.Interpolation.linear),
      quality: 85,
    );

Future<SkinPrediction> classifySkinImage(String path) async {
  final input = await compute(_prepareTensor, await File(path).readAsBytes());
  final session = await _getSession();
  final tensor = await OrtValue.fromList(input, const [1, 3, modelInputSize, modelInputSize]);
  final outputs = await session.run({'image': tensor});
  try {
    final binary = await outputs['binary_logit']!.asFlattenedList();
    final classes = await outputs['class_logits']!.asFlattenedList();
    return interpretOutputs(
      (binary.first as num).toDouble(),
      [for (final value in classes) (value as num).toDouble()],
    );
  } finally {
    await tensor.dispose();
    for (final value in outputs.values) {
      await value.dispose();
    }
  }
}

Future<Uint8List> prepareUploadImage(String path) async =>
    compute(_prepareUpload, await File(path).readAsBytes());
