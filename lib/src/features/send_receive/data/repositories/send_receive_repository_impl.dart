import 'package:fpdart/fpdart.dart';
import 'package:ztc_bank/src/utils/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';
import 'package:ztc_bank/src/features/send_receive/domain/repositories/send_receive_repository.dart';
import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

class SendReceiveRepositoryImpl implements SendReceiveRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Matches against username, full name, or Zetra ID. Excludes the
  /// current user from their own search results.
  @override
  FutureEither<List<User>> searchUsers({required String query}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }
      if (query.trim().isEmpty) {
        return right(const []);
      }

      final rows = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%,zetra_id.ilike.%$query%')
          .neq('id', currentUser.id)
          .limit(20);

      final users = (rows as List)
          .map((e) => User.fromProfileRow(e as Map<String, dynamic>))
          .toList();
      return right(users);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<User> getUserByEmail(String email) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .or('email.eq.$email,zetramail.eq.$email')
          .maybeSingle();

      if (data == null) {
        return left(const ServerFailure('User not found'));
      }
      return right(User.fromProfileRow(data));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<User> getUserById(String id) async {
    try {
      final data = await _client.from('profiles').select().eq('id', id).maybeSingle();
      if (data == null) {
        return left(const ServerFailure('User not found'));
      }
      return right(User.fromProfileRow(data));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  /// No dedicated "recent recipients" table exists yet — derives it from
  /// this user's own outgoing transfer history instead. Returns an empty
  /// list rather than erroring if there's no history yet.
  @override
  FutureEither<List<User>> getRecentRecipients({int limit = 10}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }
      // No recipient linkage column exists on transactions yet, so this
      // returns empty for now rather than guessing at a query. Revisit
      // once transactions has a way to record the counterparty.
      return right(const []);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> transfer({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }

      final senderWallet = await _client
          .from('wallets')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (senderWallet == null) {
        return left(const ServerFailure('No wallet found'));
      }

      final result = await _client.rpc('transfer_cp_by_user_id', params: {
        'p_sender_wallet_id': senderWallet['id'],
        'p_recipient_user_id': recipientId,
        'p_amount': amount,
        'p_description': description,
      });

      if (result is Map && result['success'] == true) {
        final data = await _client
            .from('transactions')
            .select()
            .eq('wallet_id', senderWallet['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .single();
        return right(TransactionModel.fromJson(data));
      }
      return left(const ServerFailure('Transfer failed'));
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  /// Not yet implemented — CP has no "request payment" concept in the
  /// current schema. Returns a clear failure instead of silently no-op'ing.
  @override
  FutureEither<Transaction> requestMoney({
    required String senderEmail,
    required double amount,
    required String description,
  }) async {
    return left(const ServerFailure('Requesting CP is not available yet'));
  }

  /// QR generation not yet implemented server-side — returns the user's
  /// own Zetra ID as a placeholder payload so the Receive screen has
  /// something scannable/shareable in the meantime.
  @override
  FutureEither<String> generateReceiveQRCode() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const ServerFailure('User not authenticated'));
      }
      final profile = await _client
          .from('profiles')
          .select('zetra_id')
          .eq('id', currentUser.id)
          .maybeSingle();

      final zetraId = profile?['zetra_id'] as String?;
      if (zetraId == null) {
        return left(const ServerFailure('Zetra ID not found'));
      }
      return right(zetraId);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Map<String, dynamic>> parseQRCode(String qrData) async {
    // Placeholder assumes the QR payload IS the Zetra ID string directly.
    return right({'zetraId': qrData});
  }
}
