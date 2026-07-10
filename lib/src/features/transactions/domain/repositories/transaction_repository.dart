import 'package:ztc_bank/src/utils/utils.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';

abstract class TransactionRepository {
  /// Get all transactions with optional filtering
  FutureEither<List<Transaction>> getAllTransactions({
    TransactionFilter? filter,
  });

  /// Get a single transaction by ID
  FutureEither<Transaction> getTransactionById(String id);

  /// Search transactions
  FutureEither<List<Transaction>> searchTransactions({
    required String query,
    TransactionFilter? filter,
  });

  /// Get transactions by type
  FutureEither<List<Transaction>> getTransactionsByType({
    required TransactionType type,
    TransactionFilter? filter,
  });

  /// Get transactions by status
  FutureEither<List<Transaction>> getTransactionsByStatus({
    required TransactionStatus status,
    TransactionFilter? filter,
  });

  /// Get transaction statistics
  FutureEither<Map<String, dynamic>> getTransactionStats();
}
