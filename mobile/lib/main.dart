import 'package:cash_compass/app.dart';
import 'package:cash_compass/core/api/api_client.dart';
import 'package:cash_compass/core/storage/token_storage.dart';
import 'package:cash_compass/features/accounts/data/accounts_repository.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:cash_compass/features/categories/data/categories_repository.dart';
import 'package:cash_compass/features/transactions/data/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:cash_compass/features/budgets/data/budgets_repository.dart';
import 'package:cash_compass/features/analytics/data/analytics_repository.dart';
import 'package:cash_compass/features/stipend/data/stipend_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);

  runApp(
    CashCompassApp(
      authRepository: AuthRepository(apiClient, tokenStorage),
      accountsRepository: AccountsRepository(apiClient),
      categoriesRepository: CategoriesRepository(apiClient),
      transactionsRepository: TransactionsRepository(apiClient),
      budgetsRepository: BudgetsRepository(apiClient),
      analyticsRepository: AnalyticsRepository(apiClient),
      stipendRepository: StipendRepository(apiClient),
    ),
  );
}