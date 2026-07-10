import 'package:equatable/equatable.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

class TransactionFilter extends Equatable {
  final String? searchQuery;
  final TransactionType? type;
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final int limit;
  final int offset;

  const TransactionFilter({
    this.searchQuery,
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.limit = 20,
    this.offset = 0,
  });

  TransactionFilter copyWith({
    String? searchQuery,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int? limit,
    int? offset,
  }) {
    return TransactionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    type,
    status,
    startDate,
    endDate,
    minAmount,
    maxAmount,
    limit,
    offset,
  ];
}
