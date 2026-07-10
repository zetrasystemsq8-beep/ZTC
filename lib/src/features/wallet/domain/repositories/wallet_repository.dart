import 'package:ztc_bank/src/utils/utils.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

abstract class WalletRepository {
  /// Get the current user's wallet
  FutureEither<Wallet> getWallet();

  /// Get recent transactions
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10});

  /// Deposit funds
  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  });

  /// Withdraw funds
  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  });

  /// Send money to another user
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  });

  /// Receive money (request)
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  });
}
