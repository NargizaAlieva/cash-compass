import 'package:cash_compass/app.dart';
import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/core/storage/token_storage.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authRepository = AuthRepository(apiClient, tokenStorage);

  runApp(CashCompassApp(authRepository: authRepository));
}