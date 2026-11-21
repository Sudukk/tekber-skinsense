// Temporary local profile stub matching ../skinsense/lib/services.dart
// so HomeScreen works standalone on feat-home-page before Supabase/auth is merged.

Map<String, dynamic> _localProfile = {
  'full_name': 'Demo',
  'gender': 'male',
  'birth_date': '2000-01-01',
  'phone': '08123456789',
};

void setLocalProfileForTesting(Map<String, dynamic> profile) {
  _localProfile = Map<String, dynamic>.from(profile);
}

Future<Map<String, dynamic>> getCurrentUserProfile() async {
  return Map<String, dynamic>.from(_localProfile);
}

Future<void> updateCurrentUserProfile({
  required String fullName,
  required String gender,
  required String birthDate,
  required String phone,
}) async {
  _localProfile = {
    'full_name': fullName,
    'gender': gender,
    'birth_date': birthDate,
    'phone': phone,
  };
}
