import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ztc_bank/src/utils/utils.dart';
import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ztc_bank/src/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Either<Failure, String>> _resolveWalletId() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return left(const ServerFailure('User not authenticated'));
    }

    final wallet = await _client
        .from('wallets')
        .select('id')
        .eq('user_id', currentUser.id)
        .maybeSingle();

    if (wallet == null) {
      return left(const ServerFailure('No wallet found'));
    }

    return right(wallet['id'] as String);
  }

  static String _typeToDb(TransactionType type) {
    switch (type) {
      case TransactionType.credit:
        return 'credit';
      case TransactionType.debit:
        return 'debit';
      case TransactionType.transferIn:
        return 'transfer_in';
      case TransactionType.transferOut:
        return 'transfer_out';
    }
  }

  /// Builds and runs the base query with every optional filter applied,
  /// returning parsed [Transaction]s.
  Future<Either<Failure, List<Transaction>>> _query({
    required String walletId,
    String? searchQuery,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // The DB has no status column, so every stored row is effectively
      // "completed". Filtering for anything else correctly yields nothing.
      if (status != null && status != TransactionStatus.completed) {
        return right(<Transaction>[]);
      }

      var query = _client.from('transactions').select().eq('wallet_id', walletId);

      if (type != null) {
        query = query.eq('type', _typeToDb(type));
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('description', '%$searchQuery%');
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }
      if (minAmount != null) {
        query = query.gte('amount', minAmount);
      }
      if (maxAmount != null) {
        query = query.lte('amount', maxAmount);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final transactions = (rows as List)
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return right(transactions);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> getAllTransactions({
    TransactionFilter? filter,
  }) async {
    final walletResult = await _resolveWalletId();
    return walletResult.fold(
      (failure) => left(failure),
      (walletId) => _query(
        walletId: walletId,
        searchQuery: filter?.searchQuery,
        type: filter?.type,
        status: filter?.status,
        startDate: filter?.startDate,
        endDate: filter?.endDate,
        minAmount: filter?.minAmount,
        maxAmount: filter?.maxAmount,
        limit: filter?.limit ?? 20,
        offset: filter?.offset ?? 0,
      ),
    );
  }

  @override
  FutureEither<Transaction> getTransactionById(String id) async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        return left(const ServerFailure('Transaction not found'));
      }

      return right(TransactionModel.fromJson(data));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> searchTransactions({
    required String query,
    TransactionFilter? filter,
  }) async {
    final walletResult = await _resolveWalletId();
    return walletResult.fold(
      (failure) => left(failure),
      (walletId) => _query(
        walletId: walletId,
        searchQuery: query,
        type: filter?.type,
        status: filter?.status,
        startDate: filter?.startDate,
        endDate: filter?.endDate,
        minAmount: filter?.minAmount,
        maxAmount: filter?.maxAmount,
        limit: filter?.limit ?? 20,
        offset: filter?.offset ?? 0,
      ),
    );
  }

  @override
  FutureEither<List<Transaction>> getTransactionsByType({
    required TransactionType type,
    TransactionFilter? filter,
  }) async {
    final walletResult = await _resolveWalletId();
    return walletResult.fold(
      (failure) => left(failure),
      (walletId) => _query(
        walletId: walletId,
        type: type,
        searchQuery: filter?.searchQuery,
        status: filter?.status,
        startDate: filter?.startDate,
        endDate: filter?.endDate,
        minAmount: filter?.minAmount,
        maxAmount: filter?.maxAmount,
        limit: filter?.limit ?? 20,
        offset: filter?.offset ?? 0,
      ),
    );
  }

  @override
  FutureEither<List<Transaction>> getTransactionsByStatus({
    required TransactionStatus status,
    TransactionFilter? filter,
  }) async {
    final walletResult = await _resolveWalletId();
    return walletResult.fold(
      (failure) => left(failure),
      (walletId) => _query(
        walletId: walletId,
        status: status,
        searchQuery: filter?.searchQuery,
        type: filter?.type,
        startDate: filter?.startDate,
        endDate: filter?.endDate,
        minAmount: filter?.minAmount,
        maxAmount: filter?.maxAmount,
        limit: filter?.limit ?? 20,
        offset: filter?.offset ?? 0,
      ),
    );
  }

  @override
  FutureEither<Map<String, dynamic>> getTransactionStats() async {
    final walletResult = await _resolveWalletId();

    return walletResult.fold(
      (failure) => left(failure),
      (walletId) async {
        try {
          final rows = await _client
              .from('transactions')
              .select()
              .eq('wallet_id', walletId);

          final transactions = (rows as List)
              .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
              .toList();

          double income = 0;
          double outflow = 0;
          for (final tx in transactions) {
            if (tx.isCredit) {
              income += tx.amount;
            } else {
              outflow += tx.amount;
            }
          }

          return right({
            'totalCount': transactions.length,
            'totalIncome': income,
            'totalOutflow': outflow,
            'netChange': income - outflow,
          });
        } catch (e) {
          return left(ServerFailure(e.toString()));
        }
      },
    );
  }
}
