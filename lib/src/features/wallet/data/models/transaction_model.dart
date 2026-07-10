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
      walletId: json['walletId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: _parseTransactionType(json['type']),
      status: _parseTransactionStatus(json['status']),
      description: json['description'] as String? ?? '',
      recipientEmail: json['recipientEmail'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'recipientEmail': recipientEmail,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static TransactionType _parseTransactionType(dynamic value) {
    if (value is String) {
      return TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => TransactionType.transfer,
      );
    }
    return TransactionType.transfer;
  }

  static TransactionStatus _parseTransactionStatus(dynamic value) {
    if (value is String) {
      return TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => TransactionStatus.pending,
      );
    }
    return TransactionStatus.pending;
  }
}
