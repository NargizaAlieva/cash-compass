import 'package:cash_compass/core/ui/confirm_dialog.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:cash_compass/features/auth/bloc/auth_bloc.dart';
import 'package:cash_compass/features/stipend/ui/stipend_settings_dialog.dart';
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
    final stipendDay = user?.stipendDay;
    final stipendAmount = user?.stipendAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      // Shows an error if saving the stipend settings failed
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        child: ListView(
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
              ),
              title: Text(name),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Stipend'),
              subtitle: Text(
                stipendDay == null
                    ? 'Not set. Tap to set the day'
                    : 'Every month on day $stipendDay'
                        '${stipendAmount == null ? '' : ' · ${formatMoney(stipendAmount)}'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => editStipendSettings(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}