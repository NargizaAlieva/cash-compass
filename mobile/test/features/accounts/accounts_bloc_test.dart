import 'package:bloc_test/bloc_test.dart';
import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/features/accounts/bloc/accounts_bloc.dart';
import 'package:cash_compass/features/accounts/data/account.dart';
import 'package:cash_compass/features/accounts/data/accounts_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

const cash = Account(
  id: 1,
  name: 'Cash',
  type: AccountType.cash,
  currency: 'KGS',
  balance: 15000,
);
const card = Account(
  id: 2,
  name: 'Kaspi Gold',
  type: AccountType.card,
  currency: 'KGS',
  balance: 80000,
);

void main() {
  late MockAccountsRepository repository;

  setUpAll(() {
    registerFallbackValue(AccountType.card);
  });

  setUp(() {
    repository = MockAccountsRepository();
  });

  test('initial state is empty', () {
    expect(AccountsBloc(repository).state, const AccountsState());
  });

  blocTest<AccountsBloc, AccountsState>(
    'AccountsRequested loads accounts and total',
    build: () {
      when(() => repository.fetchAccounts()).thenAnswer(
        (_) async =>
            const AccountsSummary(accounts: [cash, card], totalBalance: 95000),
      );
      return AccountsBloc(repository);
    },
    act: (bloc) => bloc.add(const AccountsRequested()),
    expect: () => [
      const AccountsState(status: AccountsStatus.loading),
      const AccountsState(
        status: AccountsStatus.success,
        accounts: [cash, card],
        totalBalance: 95000,
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'AccountsRequested emits failure when the server is down',
    build: () {
      when(() => repository.fetchAccounts())
          .thenThrow(const ApiException('No connection to the server'));
      return AccountsBloc(repository);
    },
    act: (bloc) => bloc.add(const AccountsRequested()),
    expect: () => [
      const AccountsState(status: AccountsStatus.loading),
      const AccountsState(
        status: AccountsStatus.failure,
        errorMessage: 'No connection to the server',
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'AccountAdded creates the account and reloads the list',
    build: () {
      when(
        () => repository.createAccount(
          name: any(named: 'name'),
          type: any(named: 'type'),
          balance: any(named: 'balance'),
        ),
      ).thenAnswer((_) async {});
      when(() => repository.fetchAccounts()).thenAnswer(
        (_) async =>
            const AccountsSummary(accounts: [cash, card], totalBalance: 95000),
      );
      return AccountsBloc(repository);
    },
    seed: () => const AccountsState(
      status: AccountsStatus.success,
      accounts: [cash],
      totalBalance: 15000,
    ),
    act: (bloc) => bloc.add(
      const AccountAdded(
        name: 'Kaspi Gold',
        type: AccountType.card,
        balance: 80000,
      ),
    ),
    expect: () => [
      const AccountsState(
        status: AccountsStatus.success,
        accounts: [cash, card],
        totalBalance: 95000,
      ),
    ],
    verify: (_) {
      verify(
        () => repository.createAccount(
          name: 'Kaspi Gold',
          type: AccountType.card,
          balance: 80000,
        ),
      ).called(1);
    },
  );

  blocTest<AccountsBloc, AccountsState>(
    'AccountDeleted shows an error and keeps the list if the server fails',
    build: () {
      when(() => repository.deleteAccount(any()))
          .thenThrow(const ApiException('Account not found'));
      return AccountsBloc(repository);
    },
    seed: () => const AccountsState(
      status: AccountsStatus.success,
      accounts: [cash],
      totalBalance: 15000,
    ),
    act: (bloc) => bloc.add(const AccountDeleted(1)),
    expect: () => [
      const AccountsState(
        status: AccountsStatus.success,
        accounts: [cash],
        totalBalance: 15000,
        errorMessage: 'Account not found',
      ),
    ],
    verify: (_) => verifyNever(() => repository.fetchAccounts()),
  );
}