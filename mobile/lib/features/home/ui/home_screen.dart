import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/accounts/ui/total_balance_card.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select((AuthBloc bloc) => bloc.state.user?.name);
    final total = context.select((AccountsBloc bloc) => bloc.state.totalBalance);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CashCompass')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hello, ${name ?? ''}!', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TotalBalanceCard(total: total),
          const SizedBox(height: 24),
          const Text(
            'Transactions and analytics are coming in stage 3.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}