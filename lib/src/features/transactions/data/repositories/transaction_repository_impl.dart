import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:ztc_bank/src/utils/utils.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ztc_bank/src/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DioService _dioService = DioService.instance;

  @override
  FutureEither<List<Transaction>> getAllTransactions({
    TransactionFilter? filter,
  }) async {
    try {
      final queryParams = _buildQueryParams(filter);
      final response = await _dioService.get(
        '/transactions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final transactions = data
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(transactions);
      }

      return left(ServerFailure('Failed to fetch transactions'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> getTransactionById(String id) async {
    try {
      final response = await _dioService.get('/transactions/$id');

      if (response.statusCode == 200) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }

      return left(ServerFailure('Transaction not found'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> searchTransactions({
    required String query,
    TransactionFilter? filter,
  }) async {
    try {
      final params = _buildQueryParams(
        filter?.copyWith(searchQuery: query) ?? TransactionFilter(searchQuery: query),
      );
      final response = await _dioService.get(
        '/transactions/search',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final transactions = data
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(transactions);
      }

      return left(ServerFailure('Search failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> getTransactionsByType({
    required TransactionType type,
    TransactionFilter? filter,
  }) async {
    try {
      final params = _buildQueryParams(
        filter?.copyWith(type: type) ?? TransactionFilter(type: type),
      );
      final response = await _dioService.get(
        '/transactions/type/${type.toString().split('.').last}',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final transactions = data
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(transactions);
      }

      return left(ServerFailure('Failed to fetch transactions'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> getTransactionsByStatus({
    required TransactionStatus status,
    TransactionFilter? filter,
  }) async {
    try {
      final params = _buildQueryParams(
        filter?.copyWith(status: status) ?? TransactionFilter(status: status),
      );
      final response = await _dioService.get(
        '/transactions/status/${status.toString().split('.').last}',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final transactions = data
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(transactions);
      }

      return left(ServerFailure('Failed to fetch transactions'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Map<String, dynamic>> getTransactionStats() async {
    try {
      final response = await _dioService.get('/transactions/stats');

      if (response.statusCode == 200) {
        final stats = response.data as Map<String, dynamic>;
        return right(stats);
      }

      return left(ServerFailure('Failed to fetch statistics'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  Map<String, dynamic> _buildQueryParams(TransactionFilter? filter) {
    if (filter == null) return {};

    final params = <String, dynamic>{};

    if (filter.searchQuery != null) params['search'] = filter.searchQuery;
    if (filter.type != null) params['type'] = filter.type.toString().split('.').last;
    if (filter.status != null) params['status'] = filter.status.toString().split('.').last;
    if (filter.startDate != null) params['startDate'] = filter.startDate!.toIso8601String();
    if (filter.endDate != null) params['endDate'] = filter.endDate!.toIso8601String();
    if (filter.minAmount != null) params['minAmount'] = filter.minAmount;
    if (filter.maxAmount != null) params['maxAmount'] = filter.maxAmount;

    params['limit'] = filter.limit;
    params['offset'] = filter.offset;

    return params;
  }
}
