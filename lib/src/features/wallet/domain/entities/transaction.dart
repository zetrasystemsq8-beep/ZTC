import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit, transferIn, transferOut }
enum TransactionStatus { pending, completed, failed }

class Transaction extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String description;
  final String? recipientEmail;
  final DateTime timestamp;

  const Transaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    this.recipientEmail,
    required this.timestamp,
  });

  /// Money coming IN to this wallet (credit or transfer_in) vs OUT (debit or transfer_out).
  bool get isCredit =>
      type == TransactionType.credit || type == TransactionType.transferIn;

  @override
  List<Object?> get props => [
    id,
    walletId,
    amount,
    type,
    status,
    description,
    recipientEmail,
    timestamp,
  ];
}
