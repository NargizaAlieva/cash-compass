import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/accounts/data/accounts_repository.dart';
import 'package:cash_compass/features/analytics/bloc/analytics_bloc.dart';
import 'package:cash_compass/features/analytics/data/analytics_repository.dart';
import 'package:cash_compass/features/analytics/ui/analytics_screen.dart';
import 'package:cash_compass/features/budgets/bloc/budgets_bloc.dart';
import 'package:cash_compass/features/budgets/data/budgets_repository.dart';
import 'package:cash_compass/features/categories/bloc/categories_bloc.dart';
import 'package:cash_compass/features/categories/data/categories_repository.dart';
import 'package:cash_compass/features/categories/ui/categories_screen.dart';
import 'package:cash_compass/features/home/ui/home_screen.dart';
import 'package:cash_compass/features/profile/ui/profile_screen.dart';
import 'package:cash_compass/features/transactions/bloc/transactions_bloc.dart';
import 'package:cash_compass/features/transactions/data/transactions_repository.dart';
import 'package:cash_compass/features/transactions/ui/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main part of the app after login: bottom navigation with 5 tabs.
///
/// The Blocs are created here, so after logout they are closed
/// and the next user starts with empty data.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Which tab is open. This is pure UI state, so setState is fine here.
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AccountsBloc(context.read<AccountsRepository>())
                ..add(const AccountsRequested()),
        ),
        BlocProvider(
          create: (context) =>
              CategoriesBloc(context.read<CategoriesRepository>())
                ..add(const CategoriesRequested()),
        ),
        BlocProvider(
          create: (context) =>
              TransactionsBloc(context.read<TransactionsRepository>())
                ..add(const TransactionsRequested()),
        ),
        BlocProvider(
          create: (context) =>
              BudgetsBloc(context.read<BudgetsRepository>())
                ..add(const BudgetsRequested()),
        ),
        // NEW: analytics for the selected month
        BlocProvider(
          create: (context) =>
              AnalyticsBloc(context.read<AnalyticsRepository>())
                ..add(const AnalyticsRequested()),
        ),
      ],
      // Here the Blocs "talk" to each other. They do not know about
      // each other: these listeners connect them.
      child: MultiBlocListener(
        listeners: [
          // A transaction changed -> balances, limits and analytics changed
          BlocListener<TransactionsBloc, TransactionsState>(
            listenWhen: (previous, current) =>
                previous.changeCount != current.changeCount,
            listener: (context, state) {
              context.read<AccountsBloc>().add(const AccountsRequested());
              context.read<BudgetsBloc>().add(const BudgetsRequested());
              // NEW: charts must show the new transaction too
              context.read<AnalyticsBloc>().add(const AnalyticsRequested());
            },
          ),
          // A category was deleted -> the server also deleted its limit
          BlocListener<CategoriesBloc, CategoriesState>(
            listenWhen: (previous, current) =>
                current.categories.length < previous.categories.length,
            listener: (context, state) =>
                context.read<BudgetsBloc>().add(const BudgetsRequested()),
          ),
          // Errors about limits can happen on any tab
          BlocListener<BudgetsBloc, BudgetsState>(
            listenWhen: (previous, current) =>
                current.errorMessage != null &&
                previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            },
          ),
        ],
        child: Scaffold(
          // IndexedStack keeps every tab alive, so switching tabs is instant
          body: IndexedStack(
            index: _tabIndex,
            children: const [
              HomeScreen(),
              TransactionsScreen(),
              AnalyticsScreen(), // NEW: instead of AccountsScreen
              CategoriesScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => setState(() => _tabIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'History',
              ),
              // NEW: instead of the Accounts tab
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}