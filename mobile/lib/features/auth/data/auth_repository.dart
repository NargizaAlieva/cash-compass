import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/core/storage/token_storage.dart';
import 'package:cash_compass/features/auth/data/user.dart';

/// Everything about auth: server requests + saving the token.
class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<User> login(String email, String password) async {
    final data = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await _tokenStorage.save(data['access_token'] as String);
    return getMe();
  }

  Future<User> register(String name, String email, String password) async {
    final data = await _api.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    await _tokenStorage.save(data['access_token'] as String);
    return getMe();
  }

  Future<User> getMe() async {
    final data = await _api.get('/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Returns the user if a valid token is saved, otherwise null.
  Future<User?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) {
      return null;
    }
    try {
      return await getMe();
    } on ApiException catch (error) {
      // Token expired or invalid: forget it
      if (error.statusCode == 401) {
        await _tokenStorage.delete();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _tokenStorage.delete();

  /// Saves the stipend day (1-31) and the amount (null = not set).
  Future<User> updateStipendSettings({
    required int stipendDay,
    double? stipendAmount,
  }) async {
    final data = await _api.put(
      '/auth/me',
      data: {'stipend_day': stipendDay, 'stipend_amount': stipendAmount},
    );
    return User.fromJson(data as Map<String, dynamic>);
  }
}