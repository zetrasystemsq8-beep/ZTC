import 'package:fpdart/fpdart.dart';
import 'package:ztc_bank/src/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:ztc_bank/src/features/wallet/data/models/wallet_model.dart';
import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  FutureEither<Wallet> getWallet() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }

      final data = await _client
          .from('wallets')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (data == null) {
        return left(const ServerFailure('No wallet found'));
      }

      return right(WalletModel.fromJson(data));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }

      final rows = await _client
          .from('transactions')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit);

      final transactions = (rows as List)
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return right(transactions);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Transaction>> _createTransaction({
    required String walletId,
    required String userId,
    required double amount,
    required String type,
    required String description,
    String? recipientEmail,
  }) async {
    try {
      final payload = {
        'wallet_id': walletId,
        'user_id': userId,
        'amount': amount,
        'type': type,
        'description': description,
        'status': 'completed',
        if (recipientEmail != null) 'recipient_email': recipientEmail,
      };

      final data = await _client.from('transactions').insert(payload).select().single();
      return right(TransactionModel.fromJson(data));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return left(const ServerFailure('User not authenticated'));
    }
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
        userId: currentUser.id,
        amount: amount,
        type: 'credit',
        description: description,
      ),
    );
  }

  @override
  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return left(const ServerFailure('User not authenticated'));
    }
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
        userId: currentUser.id,
        amount: amount,
        type: 'debit',
        description: description,
      ),
    );
  }

  @override
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return left(const ServerFailure('User not authenticated'));
    }
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
        userId: currentUser.id,
        amount: amount,
        type: 'transfer',
        description: description,
        recipientEmail: recipientEmail,
      ),
    );
  }

  @override
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return left(const ServerFailure('User not authenticated'));
    }
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
        userId: currentUser.id,
        amount: amount,
        type: 'credit',
        description: description,
      ),
    );
  }
}
