import 'package:fpdart/fpdart.dart';
import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        return left(Failure('User not authenticated'));
      }

      final result = await _dioService.get(
        '/wallets?user_id=eq.${currentUser.id}&select=*',
      );

      return result.fold(
        (failure) => left(failure),
        (response) {
          if (response.data is! List || (response.data as List).isEmpty) {
            return left(Failure('No wallet found'));
          }
          final data = (response.data as List).first as Map<String, dynamic>;
          final wallet = WalletModel.fromJson(data);
          return right(wallet);
        },
      );
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        return left(Failure('User not authenticated'));
      }

      final result = await _dioService.get(
        '/transactions?user_id=eq.${currentUser.id}&select=*&order=created_at.desc&limit=$limit',
      );

      return result.fold(
        (failure) => left(failure),
        (response) {
          if (response.data is! List) {
            return left(Failure('Invalid response format'));
          }
          final transactions = (response.data as List)
              .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return right(transactions);
        },
      );
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        return left(Failure('User not authenticated'));
      }

      final wallet = await getWallet();
      
      return await wallet.fold(
        (failure) => left(failure),
        (walletData) async {
          final result = await _dioService.post(
            '/transactions',
            data: {
              'wallet_id': walletData.id,
              'user_id': currentUser.id,
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
        },
      );
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        return left(Failure('User not authenticated'));
      }

      final wallet = await getWallet();
      
      return await wallet.fold(
        (failure) => left(failure),
        (walletData) async {
          final result = await _dioService.post(
            '/transactions',
            data: {
              'wallet_id': walletData.id,
              'user_id': currentUser.id,
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
        },
      );
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        return left(Failure('User not authenticated'));
      }

      final wallet = await getWallet();
      
      return await wallet.fold(
        (failure) => left(failure),
        (walletData) async {
          final result = await _dioService.post(
            '/transactions',
            data: {
              'wallet_id': walletData.id,
              'user_id': currentUser.id,
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
        },
      );
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        return left(Failure('User not authenticated'));
      }

      final wallet = await getWallet();
      
      return await wallet.fold(
        (failure) => left(failure),
        (walletData) async {
          final result = await _dioService.post(
            '/transactions',
            data: {
              'wallet_id': walletData.id,
              'user_id': currentUser.id,
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
        },
      );
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
