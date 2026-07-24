import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/data/repositories/wallet_repository_impl.dart';

// Repository Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl();
});

// Wallet State Notifier
class WalletNotifier extends StateNotifier<AsyncValue<Wallet>> {
  final WalletRepository _repository;

  WalletNotifier({required WalletRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> fetchWallet() async {
    state = const AsyncValue.loading();

    final result = await _repository.getWallet();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (wallet) => AsyncValue.data(wallet),
    );
  }

  Future<void> deposit(double amount, String description) async {
    final result = await _repository.deposit(
      amount: amount,
      description: description,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (transaction) {
        fetchWallet();
      },
    );
  }

  Future<void> withdraw(double amount, String description) async {
    final result = await _repository.withdraw(
      amount: amount,
      description: description,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (transaction) {
        fetchWallet();
      },
    );
  }

  Future<void> send(double amount, String recipientEmail, String description) async {
    final result = await _repository.send(
      amount: amount,
      recipientEmail: recipientEmail,
      description: description,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (transaction) {
        fetchWallet();
      },
    );
  }

  Future<void> receive(double amount, String description) async {
    final result = await _repository.receive(
      amount: amount,
      description: description,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (transaction) {
        fetchWallet();
      },
    );
  }
}

// Wallet Provider
final walletProvider = StateNotifierProvider<WalletNotifier, AsyncValue<Wallet>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repository: repository)..fetchWallet();
});

// Transactions State Notifier
class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final WalletRepository _repository;

  TransactionsNotifier({required WalletRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> fetchTransactions({int limit = 10}) async {
    state = const AsyncValue.loading();

    final result = await _repository.getRecentTransactions(limit: limit);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transactions) => AsyncValue.data(transactions),
    );
  }
}

// Transactions Provider
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return TransactionsNotifier(repository: repository)..fetchTransactions();
});
