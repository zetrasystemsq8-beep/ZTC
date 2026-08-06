import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final int balanceCents;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.balanceCents,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    int? balanceCents,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      balanceCents: balanceCents ?? this.balanceCents,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, balance, balanceCents, currency, createdAt, updatedAt];
}
