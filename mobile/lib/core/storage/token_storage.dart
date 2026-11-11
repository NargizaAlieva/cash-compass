import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the JWT token in encrypted storage on the device.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String token) => _storage.write(key: _key, value: token);

  Future<void> delete() => _storage.delete(key: _key);
}