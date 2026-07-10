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
    try {
      final response = await _dioService.get('/wallet');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final wallet = WalletModel.fromJson(data);
        return right(wallet);
      }
      
      return left(ServerFailure('Failed to fetch wallet'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final response = await _dioService.get(
        '/wallet/transactions',
        queryParameters: {'limit': limit},
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
  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  }) async {
    try {
      final response = await _dioService.post(
        '/wallet/deposit',
        data: {
          'amount': amount,
          'description': description,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }
      
      return left(ServerFailure('Deposit failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  }) async {
    try {
      final response = await _dioService.post(
        '/wallet/withdraw',
        data: {
          'amount': amount,
          'description': description,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }
      
      return left(ServerFailure('Withdrawal failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  }) async {
    try {
      final response = await _dioService.post(
        '/wallet/send',
        data: {
          'amount': amount,
          'recipientEmail': recipientEmail,
          'description': description,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }
      
      return left(ServerFailure('Send failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  }) async {
    try {
      final response = await _dioService.post(
        '/wallet/receive',
        data: {
          'amount': amount,
          'description': description,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }
      
      return left(ServerFailure('Receive failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
