import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Temporary home screen. Accounts and transactions come in stage 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CashCompass'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hello, ${user?.name ?? ''}!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(user?.email ?? '', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              const Text(
                'Accounts and transactions are coming in stage 2.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}