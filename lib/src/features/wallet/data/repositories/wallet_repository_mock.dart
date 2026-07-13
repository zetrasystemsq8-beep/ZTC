import 'package:fpdart/fpdart.dart';
import 'package:ztc_bank/src/utils/utils.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/domain/repositories/wallet_repository.dart';

/// In-memory mock implementation of [WalletRepository] used while the
/// backend (Rust API / Firebase) is not yet available.
///
/// Swap this out by binding `walletRepositoryProvider` to a real
/// implementation (e.g. `WalletRepositoryImpl` which talks to Dio) once
/// the backend is live. No UI or provider code needs to change.
class WalletRepositoryMock implements WalletRepository {
  WalletRepositoryMock();

  static const _networkDelay = Duration(milliseconds: 350);

  Wallet _wallet = Wallet(
    id: '10029384',
    userId: 'demo-user',
    balance: 12480.75,
    currency: 'USD',
    createdAt: DateTime.now().subtract(const Duration(days: 240)),
    updatedAt: DateTime.now(),
  );

  final List<Transaction> _transactions = _seedTransactions();

  static List<Transaction> _seedTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'tx_001',
        walletId: '10029384',
        amount: 2450.00,
        type: TransactionType.credit,
        status: TransactionStatus.completed,
        description: 'Salary — Zetra Systems',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      Transaction(
        id: 'tx_002',
        walletId: '10029384',
        amount: 89.20,
        type: TransactionType.debit,
        status: TransactionStatus.completed,
        description: 'Whole Foods Market',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Transaction(
        id: 'tx_003',
        walletId: '10029384',
        amount: 320.00,
        type: TransactionType.transfer,
        status: TransactionStatus.completed,
        description: 'Transfer to Sara',
        recipientEmail: 'sara@example.com',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 'tx_004',
        walletId: '10029384',
        amount: 14.99,
        type: TransactionType.debit,
        status: TransactionStatus.completed,
        description: 'Netflix subscription',
        timestamp: now.subtract(const Duration(days: 3, hours: 5)),
      ),
      Transaction(
        id: 'tx_005',
        walletId: '10029384',
        amount: 1200.00,
        type: TransactionType.credit,
        status: TransactionStatus.completed,
        description: 'Client invoice #A-231',
        timestamp: now.subtract(const Duration(days: 4)),
      ),
      Transaction(
        id: 'tx_006',
        walletId: '10029384',
        amount: 55.40,
        type: TransactionType.debit,
        status: TransactionStatus.completed,
        description: 'Uber rides',
        timestamp: now.subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: 'tx_007',
        walletId: '10029384',
        amount: 210.00,
        type: TransactionType.debit,
        status: TransactionStatus.completed,
        description: 'Electricity bill',
        timestamp: now.subtract(const Duration(days: 6)),
      ),
      Transaction(
        id: 'tx_008',
        walletId: '10029384',
        amount: 75.00,
        type: TransactionType.debit,
        status: TransactionStatus.pending,
        description: 'Amazon.com',
        timestamp: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  void _touch() {
    _wallet = _wallet.copyWith(updatedAt: DateTime.now());
  }

  @override
  FutureEither<Wallet> getWallet() async {
    await Future<void>.delayed(_networkDelay);
    return right(_wallet);
  }

  @override
  FutureEither<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    await Future<void>.delayed(_networkDelay);
    final sorted = [..._transactions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return right(sorted.take(limit).toList(growable: false));
  }

  Transaction _record({
    required double amount,
    required TransactionType type,
    required String description,
    String? recipientEmail,
  }) {
    final tx = Transaction(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      walletId: _wallet.id,
      amount: amount,
      type: type,
      status: TransactionStatus.completed,
      description: description,
      recipientEmail: recipientEmail,
      timestamp: DateTime.now(),
    );
    _transactions.insert(0, tx);
    return tx;
  }

  @override
  FutureEither<Transaction> deposit({
    required double amount,
    required String description,
  }) async {
    await Future<void>.delayed(_networkDelay);
    _wallet = _wallet.copyWith(balance: _wallet.balance + amount);
    _touch();
    return right(_record(
      amount: amount,
      type: TransactionType.credit,
      description: description,
    ));
  }

  @override
  FutureEither<Transaction> withdraw({
    required double amount,
    required String description,
  }) async {
    await Future<void>.delayed(_networkDelay);
    if (amount > _wallet.balance) {
      return left(const ServerFailure('Insufficient funds'));
    }
    _wallet = _wallet.copyWith(balance: _wallet.balance - amount);
    _touch();
    return right(_record(
      amount: amount,
      type: TransactionType.debit,
      description: description,
    ));
  }

  @override
  FutureEither<Transaction> send({
    required double amount,
    required String recipientEmail,
    required String description,
  }) async {
    await Future<void>.delayed(_networkDelay);
    if (amount > _wallet.balance) {
      return left(const ServerFailure('Insufficient funds'));
    }
    _wallet = _wallet.copyWith(balance: _wallet.balance - amount);
    _touch();
    return right(_record(
      amount: amount,
      type: TransactionType.transfer,
      description: description,
      recipientEmail: recipientEmail,
    ));
  }

  @override
  FutureEither<Transaction> receive({
    required double amount,
    required String description,
  }) async {
    await Future<void>.delayed(_networkDelay);
    _wallet = _wallet.copyWith(balance: _wallet.balance + amount);
    _touch();
    return right(_record(
      amount: amount,
      type: TransactionType.credit,
      description: description,
    ));
  }
}
