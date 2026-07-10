import 'package:fpdart/fpdart.dart';

import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:ztc_bank/src/utils/utils.dart';

import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ztc_bank/src/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DioService _dioService = DioService.instance;

  @override
  FutureEither<List<Transaction>> getAllTransactions({
    TransactionFilter? filter,
  }) async {
    final result = await _dioService.get(
      '/transactions',
      queryParameters: filter?.toJson(),
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;

        final transactions = data
            .map(
              (e) => TransactionModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();

        return right(transactions);
      },
    );
  }

  @override
  FutureEither<Transaction> getTransactionById(String id) async {
    final result = await _dioService.get('/transactions/$id');

    return result.fold(
      (failure) => left(failure),
      (response) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        return right(transaction);
      },
    );
  }

  @override
  FutureEither<List<Transaction>> searchTransactions({
    required String query,
    TransactionFilter? filter,
  }) async {
    final params = <String, dynamic>{
      'q': query,
      ...?filter?.toJson(),
    };

    final result = await _dioService.get(
      '/transactions/search',
      queryParameters: params,
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;

        final transactions = data
            .map(
              (e) => TransactionModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();

        return right(transactions);
      },
    );
  }

  @override
  FutureEither<List<Transaction>> getTransactionsByType({
    required TransactionType type,
    TransactionFilter? filter,
  }) async {
    final params = <String, dynamic>{
      'type': type.name,
      ...?filter?.toJson(),
    };

    final result = await _dioService.get(
      '/transactions/type',
      queryParameters: params,
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;

        final transactions = data
            .map(
              (e) => TransactionModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();

        return right(transactions);
      },
    );
  }

  @override
  FutureEither<List<Transaction>> getTransactionsByStatus({
    required TransactionStatus status,
    TransactionFilter? filter,
  }) async {
    final params = <String, dynamic>{
      'status': status.name,
      ...?filter?.toJson(),
    };

    final result = await _dioService.get(
      '/transactions/status',
      queryParameters: params,
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;

        final transactions = data
            .map(
              (e) => TransactionModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();

        return right(transactions);
      },
    );
  }

  @override
  FutureEither<Map<String, dynamic>> getTransactionStats() async {
    final result = await _dioService.get('/transactions/stats');

    return result.fold(
      (failure) => left(failure),
      (response) {
        return right(
          response.data as Map<String, dynamic>,
        );
      },
    );
  }
}
