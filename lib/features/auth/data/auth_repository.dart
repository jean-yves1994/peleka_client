import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/user.dart';

class AuthRepository {
  final ApiClient _api;
  final SecureStorage _st;
  AuthRepository(this._api, this._st);

  Future<User?> currentUser() async {
    try {
      final s = await _st.readUser();
      if (s == null) return null;
      return User.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  Future<User> _finish(Map<String, dynamic> d) async {
    await _st.writeTokens(access: d['access_token'], refresh: d['refresh_token']);
    final u = User.fromJson(d['user']);
    await _st.writeUser(jsonEncode(u.toJson()));
    return u;
  }

  Future<User> login({String? email, String? phone, required String password}) async {
    final b = <String, dynamic>{'password': password};
    if (email != null && email.isNotEmpty) b['email'] = email;
    if (phone != null && phone.isNotEmpty) b['phone'] = phone;
    return _finish((await _api.post('/api/auth/login', body: b))['data']);
  }

  Future<User> register({String? email, String? confirmEmail, String? phone, String? confirmPhone, required String password, required String confirmPassword, required String fullName}) async {
    final b = <String, dynamic>{'password': password, 'confirm_password': confirmPassword, 'full_name': fullName};
    if (email != null && email.isNotEmpty) {
      b['email'] = email;
      b['confirm_email'] = confirmEmail;
    }
    if (phone != null && phone.isNotEmpty) {
      b['phone'] = phone;
      b['confirm_phone'] = confirmPhone;
    }
    return _finish((await _api.post('/api/auth/register', body: b))['data']);
  }

  Future<User> updateProfile({String? fullName, String? phone, String? avatarUrl}) async {
    final b = <String, dynamic>{};
    if (fullName != null) b['full_name'] = fullName;
    if (phone != null) b['phone'] = phone;
    if (avatarUrl != null) b['avatar_url'] = avatarUrl;
    final r = await _api.patch('/api/me', body: b);
    final u = User.fromJson(r['data']['user']);
    await _st.writeUser(jsonEncode(u.toJson()));
    return u;
  }

  Future<void> changePassword({required String current, required String next}) async {
    await _api.post('/api/me/password', body: {'current_password': current, 'new_password': next});
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', body: {});
    } catch (_) {}
    await _st.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(secureStorageProvider)));
