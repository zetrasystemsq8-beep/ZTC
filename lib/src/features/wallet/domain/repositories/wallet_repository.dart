import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

abstract class WalletRepository {
  FutureEither<Wallet> getWallet();

  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10});

  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  });

  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  });

  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  });

  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  });
}
