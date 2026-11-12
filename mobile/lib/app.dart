import 'package:cash_compass/features/accounts/data/accounts_repository.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:cash_compass/features/auth/ui/auth_screen.dart';
import 'package:cash_compass/features/categories/data/categories_repository.dart';
import 'package:cash_compass/features/shell/main_shell.dart';
import 'package:cash_compass/features/transactions/data/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cash_compass/features/budgets/data/budgets_repository.dart';
import 'package:cash_compass/features/analytics/data/analytics_repository.dart';
import 'package:cash_compass/features/stipend/data/stipend_repository.dart';

const _seedColor = Color(0xFF0F766E);

class CashCompassApp extends StatelessWidget {
  const CashCompassApp({
    super.key,
    required this.authRepository,
    required this.accountsRepository,
    required this.categoriesRepository,
    required this.transactionsRepository,
    required this.budgetsRepository,
    required this.analyticsRepository,
    required this.stipendRepository,
  });

  final AuthRepository authRepository;
  final AccountsRepository accountsRepository;
  final CategoriesRepository categoriesRepository;
  final TransactionsRepository transactionsRepository;
  final BudgetsRepository budgetsRepository;
  final AnalyticsRepository analyticsRepository;
  final StipendRepository stipendRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: accountsRepository),
        RepositoryProvider.value(value: categoriesRepository),
        RepositoryProvider.value(value: transactionsRepository),
        RepositoryProvider.value(value: budgetsRepository),
        RepositoryProvider.value(value: analyticsRepository),
        RepositoryProvider.value(value: stipendRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
        child: MaterialApp(
          title: 'CashCompass',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: _seedColor),
          darkTheme: ThemeData(
            colorSchemeSeed: _seedColor,
            brightness: Brightness.dark,
          ),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Shows the right screen depending on the auth status.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => switch (state.status) {
        AuthStatus.unknown => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.authenticated => const MainShell(),
        AuthStatus.unauthenticated => const AuthScreen(),
      },
    );
  }
}