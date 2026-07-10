import 'package:dartz/dartz.dart';
import 'package:flutter_clean_architecture/core/network/dio_service.dart';
import 'package:flutter_clean_architecture/core/error/failure.dart';
import 'package:flutter_clean_architecture/features/wallet/data/models/wallet_model.dart';
import 'package:flutter_clean_architecture/features/wallet/data/models/transaction_model.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/entities/wallet.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/entities/transaction.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/repositories/wallet_repository.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;

class WalletRepositoryImpl implements WalletRepository {
  final DioService _dioService;

  WalletRepositoryImpl(this._dioService);

  @override
  FutureEither<Wallet> getWallet() async {
    final result = await _dioService.get('/wallet');
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final walletModel = WalletModel.fromJson(data);
        return right(walletModel);
      },
    );
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions() async {
    final result = await _dioService.get('/transactions/recent');
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
  FutureEither<Transaction> deposit({
    required double amount,
    required String method,
  }) async {
    final result = await _dioService.post(
      '/transactions/deposit',
      data: {
        'amount': amount,
        'method': method,
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
  FutureEither<Transaction> withdraw({
    required double amount,
    required String method,
  }) async {
    final result = await _dioService.post(
      '/transactions/withdraw',
      data: {
        'amount': amount,
        'method': method,
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
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    String? description,
  }) async {
    final result = await _dioService.post(
      '/transactions/send',
      data: {
        'amount': amount,
        'recipientEmail': recipientEmail,
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
  FutureEither<Transaction> receive({
    required double amount,
    required String senderEmail,
    String? description,
  }) async {
    final result = await _dioService.post(
      '/transactions/receive',
      data: {
        'amount': amount,
        'senderEmail': senderEmail,
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
}
