import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.walletId,
    required super.amount,
    required super.type,
    required super.status,
    required super.description,
    super.recipientEmail,
    required super.timestamp,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String? ?? '',
      walletId: json['wallet_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: _parseTransactionType(json['type']),
      // `transactions` has no status column — every row that exists was
      // written only after a successful transfer_cp call or a successful
      // deposit/withdraw insert, so it's always completed.
      status: TransactionStatus.completed,
      description: json['description'] as String? ?? '',
      recipientEmail: null, // not stored on this table
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'amount': amount,
      'type': _typeToDb(type),
      'description': description,
      'created_at': timestamp.toIso8601String(),
    };
  }

  static TransactionType _parseTransactionType(dynamic value) {
    switch (value) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      case 'transfer_in':
        return TransactionType.transferIn;
      case 'transfer_out':
        return TransactionType.transferOut;
      default:
        return TransactionType.transferOut;
    }
  }

  static String _typeToDb(TransactionType type) {
    switch (type) {
      case TransactionType.credit:
        return 'credit';
      case TransactionType.debit:
        return 'debit';
      case TransactionType.transferIn:
        return 'transfer_in';
      case TransactionType.transferOut:
        return 'transfer_out';
    }
  }
}
