import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANONYMOUS_KEY');
const supabaseKey = _anonKey != '' ? _anonKey : String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const isSupabaseConfigured = supabaseUrl != '' && supabaseKey != '';
const oauthRedirectUrl = 'melanosense://auth/callback';
const showSocialAuth = false;

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

