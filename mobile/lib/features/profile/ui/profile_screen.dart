import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to log in again.',
      confirmText: 'Log out',
    );
    if (confirmed) {
      bloc.add(const AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final name = user?.name ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
            ),
            title: Text(name),
            subtitle: Text(user?.email ?? ''),
          ),
          const Divider(),
          // Stipend settings will be added here in stage 6
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}