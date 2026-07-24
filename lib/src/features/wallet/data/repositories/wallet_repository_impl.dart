import 'package:ztc_bank/src/imports/core_imports.dart';
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
    final result = await _dioService.get(
      '/rest/v1/wallets',
      queryParameters: {'select': '*'},
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = (response.data as List).first as Map<String, dynamic>;
        final wallet = WalletModel.fromJson(data);
        return right(wallet);
      },
    );
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final result = await _dioService.get(
      '/rest/v1/transactions',
      queryParameters: {
        'select': '*',
        'order': 'created_at.desc',
        'limit': limit,
      },
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
      '/rest/v1/transactions',
      data: {
        'wallet_id': 'get_current_wallet_id', // needs to be dynamic
        'user_id': 'auth.uid()',
        'amount': amount,
        'type': 'credit',
        'description': description,
        'status': 'completed',
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
      '/rest/v1/transactions',
      data: {
        'wallet_id': 'get_current_wallet_id',
        'user_id': 'auth.uid()',
        'amount': amount,
        'type': 'debit',
        'description': description,
        'status': 'completed',
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
      '/rest/v1/transactions',
      data: {
        'wallet_id': 'get_current_wallet_id',
        'user_id': 'auth.uid()',
        'amount': amount,
        'type': 'transfer',
        'description': description,
        'recipient_email': recipientEmail,
        'status': 'completed',
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
      '/rest/v1/transactions',
      data: {
        'wallet_id': 'get_current_wallet_id',
        'user_id': 'auth.uid()',
        'amount': amount,
        'type': 'credit',
        'description': description,
        'status': 'completed',
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
