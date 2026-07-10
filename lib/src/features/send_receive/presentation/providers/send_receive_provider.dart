import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';
import 'package:ztc_bank/src/features/send_receive/domain/repositories/send_receive_repository.dart';
import 'package:ztc_bank/src/features/send_receive/data/repositories/send_receive_repository_impl.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

// Repository Provider
final sendReceiveRepositoryProvider = Provider<SendReceiveRepository>((ref) {
  return SendReceiveRepositoryImpl();
});

// Search Users Notifier
class SearchUsersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final SendReceiveRepository _repository;

  SearchUsersNotifier({required SendReceiveRepository repository})
      : _repository = repository,
        super(const AsyncValue.data([]));

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    final result = await _repository.searchUsers(query: query);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (users) => AsyncValue.data(users),
    );
  }
}

final searchUsersProvider = StateNotifierProvider<SearchUsersNotifier, AsyncValue<List<User>>>((ref) {
  final repository = ref.watch(sendReceiveRepositoryProvider);
  return SearchUsersNotifier(repository: repository);
});

// Recent Recipients Provider
class RecentRecipientsNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final SendReceiveRepository _repository;

  RecentRecipientsNotifier({required SendReceiveRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> fetchRecentRecipients() async {
    state = const AsyncValue.loading();
    final result = await _repository.getRecentRecipients();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (users) => AsyncValue.data(users),
    );
  }
}

final recentRecipientsProvider = StateNotifierProvider<RecentRecipientsNotifier, AsyncValue<List<User>>>((ref) {
  final repository = ref.watch(sendReceiveRepositoryProvider);
  return RecentRecipientsNotifier(repository: repository)..fetchRecentRecipients();
});

// Selected Recipient Provider
final selectedRecipientProvider = StateProvider<User?>((ref) => null);

// QR Code Provider
class QRCodeNotifier extends StateNotifier<AsyncValue<String>> {
  final SendReceiveRepository _repository;

  QRCodeNotifier({required SendReceiveRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  Future<void> generateQRCode() async {
    state = const AsyncValue.loading();
    final result = await _repository.generateReceiveQRCode();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (qrCode) => AsyncValue.data(qrCode),
    );
  }
}

final qrCodeProvider = StateNotifierProvider<QRCodeNotifier, AsyncValue<String>>((ref) {
  final repository = ref.watch(sendReceiveRepositoryProvider);
  return QRCodeNotifier(repository: repository)..generateQRCode();
});

// Transfer State
class TransferNotifier extends StateNotifier<AsyncValue<Transaction>> {
  final SendReceiveRepository _repository;

  TransferNotifier({required SendReceiveRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(Transaction(
          id: '',
          walletId: '',
          amount: 0,
          type: TransactionType.transfer,
          status: TransactionStatus.pending,
          description: '',
          timestamp: DateTime.now(),
        )));

  Future<void> processTransfer({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.transfer(
      recipientId: recipientId,
      amount: amount,
      description: description,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transaction) => AsyncValue.data(transaction),
    );
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, AsyncValue<Transaction>>((ref) {
  final repository = ref.watch(sendReceiveRepositoryProvider);
  return TransferNotifier(repository: repository);
});

// Request Money State
class RequestMoneyNotifier extends StateNotifier<AsyncValue<Transaction>> {
  final SendReceiveRepository _repository;

  RequestMoneyNotifier({required SendReceiveRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(Transaction(
          id: '',
          walletId: '',
          amount: 0,
          type: TransactionType.transfer,
          status: TransactionStatus.pending,
          description: '',
          timestamp: DateTime.now(),
        )));

  Future<void> requestMoney({
    required String senderEmail,
    required double amount,
    required String description,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.requestMoney(
      senderEmail: senderEmail,
      amount: amount,
      description: description,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (transaction) => AsyncValue.data(transaction),
    );
  }
}

final requestMoneyProvider = StateNotifierProvider<RequestMoneyNotifier, AsyncValue<Transaction>>((ref) {
  final repository = ref.watch(sendReceiveRepositoryProvider);
  return RequestMoneyNotifier(repository: repository);
});
