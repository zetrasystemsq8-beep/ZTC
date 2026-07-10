import 'package:dartz/dartz.dart';
import 'package:flutter_clean_architecture/core/network/dio_service.dart';
import 'package:flutter_clean_architecture/core/error/failure.dart';
import 'package:flutter_clean_architecture/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_clean_architecture/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_clean_architecture/features/transactions/domain/repositories/transaction_repository.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;

class TransactionRepositoryImpl implements TransactionRepository {
  final DioService _dioService;

  TransactionRepositoryImpl(this._dioService);

  @override
  FutureEither<List<Transaction>> getTransactions({
    int? limit,
    int? offset,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (type != null) queryParams['type'] = type;
    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final result = await _dioService.get(
      '/transactions',
      queryParameters: queryParams,
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;
        final transactions = data
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(transactions);
      },
    );
  }

  @override
  FutureEither<Transaction> getTransactionById({required String transactionId}) async {
    final result = await _dioService.get('/transactions/$transactionId');
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final transactionModel = TransactionModel.fromJson(data);
        return right(transactionModel);
      },
    );
  }

  @override
  FutureEither<Transaction> createTransaction({
    required double amount,
    required String type,
    required String description,
    String? recipientId,
    String? senderId,
  }) async {
    final result = await _dioService.post(
      '/transactions',
      data: {
        'amount': amount,
        'type': type,
        'description': description,
        'recipientId': recipientId,
        'senderId': senderId,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final transactionModel = TransactionModel.fromJson(data);
        return right(transactionModel);
      },
    );
  }

  @override
  FutureEither<Transaction> updateTransaction({
    required String transactionId,
    String? status,
    String? description,
  }) async {
    final result = await _dioService.put(
      '/transactions/$transactionId',
      data: {
        'status': status,
        'description': description,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final transactionModel = TransactionModel.fromJson(data);
        return right(transactionModel);
      },
    );
  }

  @override
  FutureEither<bool> deleteTransaction({required String transactionId}) async {
    final result = await _dioService.delete('/transactions/$transactionId');
    return result.fold(
      (failure) => left(failure),
      (response) {
        return right(true);
      },
    );
  }

  @override
  FutureEither<double> getBalance() async {
    final result = await _dioService.get('/transactions/balance');
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final balance = data['balance'] as double;
        return right(balance);
      },
    );
  }
}
