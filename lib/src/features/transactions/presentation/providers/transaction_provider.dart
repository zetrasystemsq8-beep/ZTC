import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ztc_bank/src/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:ztc_bank/src/features/transactions/data/repositories/transaction_repository_impl.dart';

// Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});

// Transaction Filter State
final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return const TransactionFilter();
});

// Transactions List State Notifier
class TransactionsListNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionsListNotifier({required TransactionRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> fetchTransactions({TransactionFilter? filter}) async {
    state = const AsyncValue.loading();

    final result = await _repository.getAllTransactions(filter: filter);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transactions) => AsyncValue.data(transactions),
    );
  }

  Future<void> searchTransactions(String query, {TransactionFilter? filter}) async {
    state = const AsyncValue.loading();

    final result = await _repository.searchTransactions(
      query: query,
      filter: filter,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transactions) => AsyncValue.data(transactions),
    );
  }

  Future<void> filterByType(TransactionType type, {TransactionFilter? filter}) async {
    state = const AsyncValue.loading();

    final result = await _repository.getTransactionsByType(
      type: type,
      filter: filter,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transactions) => AsyncValue.data(transactions),
    );
  }

  Future<void> filterByStatus(TransactionStatus status, {TransactionFilter? filter}) async {
    state = const AsyncValue.loading();

    final result = await _repository.getTransactionsByStatus(
      status: status,
      filter: filter,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transactions) => AsyncValue.data(transactions),
    );
  }
}

// Transactions List Provider
final transactionsListProvider = StateNotifierProvider<TransactionsListNotifier, AsyncValue<List<Transaction>>>(
  (ref) {
    final repository = ref.watch(transactionRepositoryProvider);
    final filter = ref.watch(transactionFilterProvider);
    final notifier = TransactionsListNotifier(repository: repository);
    notifier.fetchTransactions(filter: filter);
    return notifier;
  },
);

// Single Transaction State Notifier
class SingleTransactionNotifier extends StateNotifier<AsyncValue<Transaction>> {
  final TransactionRepository _repository;

  SingleTransactionNotifier({required TransactionRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> fetchTransaction(String id) async {
    state = const AsyncValue.loading();

    final result = await _repository.getTransactionById(id);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transaction) => AsyncValue.data(transaction),
    );
  }
}

// Single Transaction Provider Factory
final singleTransactionProvider = StateNotifierProvider.family<
    SingleTransactionNotifier,
    AsyncValue<Transaction>,
    String
>(
  (ref, transactionId) {
    final repository = ref.watch(transactionRepositoryProvider);
    return SingleTransactionNotifier(repository: repository)..fetchTransaction(transactionId);
  },
);

// Transaction Stats Provider
class TransactionStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final TransactionRepository _repository;

  TransactionStatsNotifier({required TransactionRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();

    final result = await _repository.getTransactionStats();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (stats) => AsyncValue.data(stats),
    );
  }
}

final transactionStatsProvider = StateNotifierProvider<
    TransactionStatsNotifier,
    AsyncValue<Map<String, dynamic>>
>(
  (ref) {
    final repository = ref.watch(transactionRepositoryProvider);
    return TransactionStatsNotifier(repository: repository)..fetchStats();
  },
);
