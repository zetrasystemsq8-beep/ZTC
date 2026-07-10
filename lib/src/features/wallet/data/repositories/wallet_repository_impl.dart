import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:ztc_bank/src/utils/utils.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:ztc_bank/src/features/wallet/data/models/wallet_model.dart';
import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final DioService _dioService = DioService.instance;

  @override
  FutureEither<Wallet> getWallet() async {
    final result = await _dioService.get('/wallet');

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final wallet = WalletModel.fromJson(data);
        return right(wallet);
      },
    );
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final result = await _dioService.get(
      '/wallet/transactions',
      queryParameters: {'limit': limit},
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
  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  }) async {
    final result = await _dioService.post(
      '/wallet/deposit',
      data: {
        'amount': amount,
        'description': description,
      },
    );

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
  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  }) async {
    final result = await _dioService.post(
      '/wallet/withdraw',
      data: {
        'amount': amount,
        'description': description,
      },
    );

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
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  }) async {
    final result = await _dioService.post(
      '/wallet/send',
      data: {
        'amount': amount,
        'recipientEmail': recipientEmail,
        'description': description,
      },
    );

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
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  }) async {
    final result = await _dioService.post(
      '/wallet/receive',
      data: {
        'amount': amount,
        'description': description,
      },
    );

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
}
