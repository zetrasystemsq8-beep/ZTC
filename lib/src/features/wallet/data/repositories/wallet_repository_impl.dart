import 'package:fpdart/fpdart.dart';
import 'package:ztc_bank/src/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// transactions has no user_id column — it's scoped by wallet_id, so we
  /// resolve the user's wallet first, then query transactions against it.
  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }

      final walletResult = await getWallet();
      return await walletResult.fold(
        (failure) => left(failure),
        (wallet) async {
          final rows = await _client
              .from('transactions')
              .select()
              .eq('wallet_id', wallet.id)
              .order('created_at', ascending: false)
              .limit(limit);

          final transactions = (rows as List)
              .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return right(transactions);
        },
      );
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  /// Note: transactions has no 'status' column in the current schema —
  /// only id, wallet_id, amount, type, description, created_at.
  Future<Either<Failure, Transaction>> _createTransaction({
    required String walletId,
    required double amount,
    required String type,
    required String description,
  }) async {
    try {
      final payload = {
        'wallet_id': walletId,
        'amount': amount,
        'type': type,
        'description': description,
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
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
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
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
        amount: amount,
        type: 'debit',
        description: description,
      ),
    );
  }

  /// Real CP transfer between two users' wallets, done atomically via the
  /// transfer_cp Postgres function (debit + credit + both transaction logs
  /// happen inside one database transaction — either all succeed or all
  /// roll back). `recipientEmail` here actually carries the recipient's
  /// Zetra ID (e.g. "ZTR-100020"), not an email address — kept the param
  /// name for now to avoid touching every caller; rename to
  /// recipientZetraId when convenient.
  @override
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  }) async {
    try {
      final wallet = await getWallet();
      return await wallet.fold(
        (failure) => left(failure),
        (walletData) async {
          final result = await _client.rpc('transfer_cp', params: {
            'p_sender_wallet_id': walletData.id,
            'p_recipient_zetra_id': recipientEmail,
            'p_amount': amount,
            'p_description': description,
          });

          if (result is Map && result['success'] == true) {
            final data = await _client
                .from('transactions')
                .select()
                .eq('wallet_id', walletData.id)
                .order('created_at', ascending: false)
                .limit(1)
                .single();
            return right(TransactionModel.fromJson(data));
          }
          return left(const ServerFailure('Transfer failed'));
        },
      );
    } on PostgrestException catch (e) {
      // Postgres RAISE EXCEPTION messages from transfer_cp (e.g.
      // "Insufficient balance", "Recipient not found") surface here.
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  }) async {
    final wallet = await getWallet();
    return wallet.fold(
      (failure) => left(failure),
      (walletData) => _createTransaction(
        walletId: walletData.id,
        amount: amount,
        type: 'credit',
        description: description,
      ),
    );
  }
}
