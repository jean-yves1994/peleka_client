import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorage {
  final FlutterSecureStorage _s;
  SecureStorage([FlutterSecureStorage? s])
      : _s = s ??
            const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: false));
  static const _kA = 'peleka.access_token';
  static const _kR = 'peleka.refresh_token';
  static const _kU = 'peleka.user';
  Future<String?> readAccessToken() async {
    try {
      return await _s.read(key: _kA);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _s.read(key: _kR);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readUser() async {
    try {
      return await _s.read(key: _kU);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeTokens(
      {required String access, required String refresh}) async {
    try {
      await _s.write(key: _kA, value: access);
      await _s.write(key: _kR, value: refresh);
    } catch (_) {}
  }

  Future<void> writeUser(String u) async {
    try {
      await _s.write(key: _kU, value: u);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _s.delete(key: _kA);
      await _s.delete(key: _kR);
      await _s.delete(key: _kU);
    } catch (_) {}
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());
