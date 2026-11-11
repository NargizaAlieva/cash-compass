import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:cash_compass/features/auth/data/auth_repository.dart';
import 'package:cash_compass/features/auth/ui/auth_screen.dart';
import 'package:cash_compass/features/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _seedColor = Color(0xFF0F766E);

class CashCompassApp extends StatelessWidget {
  const CashCompassApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
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
        AuthStatus.authenticated => const HomeScreen(),
        AuthStatus.unauthenticated => const AuthScreen(),
      },
    );
  }
}