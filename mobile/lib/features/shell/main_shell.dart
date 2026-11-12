import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/accounts/data/accounts_repository.dart';
import 'package:cash_compass/features/accounts/ui/accounts_screen.dart';
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
      ],
      // When a transaction is added, changed or deleted, balances change too,
      // so we ask AccountsBloc to reload. This is how two Blocs talk.
      child: BlocListener<TransactionsBloc, TransactionsState>(
        listenWhen: (previous, current) =>
            previous.changeCount != current.changeCount,
        listener: (context, state) =>
            context.read<AccountsBloc>().add(const AccountsRequested()),
        child: Scaffold(
          // IndexedStack keeps every tab alive, so switching tabs is instant
          body: IndexedStack(
            index: _tabIndex,
            children: const [
              HomeScreen(),
              TransactionsScreen(),
              AccountsScreen(),
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
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Accounts',
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