import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:ztc_bank/src/utils/utils.dart';

import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';
import 'package:ztc_bank/src/features/send_receive/domain/repositories/send_receive_repository.dart';
import 'package:ztc_bank/src/features/wallet/data/models/transaction_model.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

class SendReceiveRepositoryImpl implements SendReceiveRepository {
  final DioService _dioService = DioService.instance;

  @override
  FutureEither<List<User>> searchUsers({
    required String query,
  }) async {
    final result = await _dioService.get(
      '/users/search',
      queryParameters: {'q': query},
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;
        final users = data
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return right(users);
      },
    );
  }

  @override
  FutureEither<User> getUserByEmail(String email) async {
    final result = await _dioService.get('/users/email/$email');

    return result.fold(
      (failure) => left(failure),
      (response) {
        final user = UserModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        return right(user);
      },
    );
  }

  @override
  FutureEither<User> getUserById(String id) async {
    final result = await _dioService.get('/users/$id');

    return result.fold(
      (failure) => left(failure),
      (response) {
        final user = UserModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        return right(user);
      },
    );
  }

  @override
  FutureEither<List<User>> getRecentRecipients({
    int limit = 10,
  }) async {
    final result = await _dioService.get(
      '/users/recipients',
      queryParameters: {
        'limit': limit,
      },
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;

        final users = data
            .map((e) => UserModel.fromJson(
                  e as Map<String, dynamic>,
                ))
            .toList();

        return right(users);
      },
    );
  }

  @override
  FutureEither<Transaction> transfer({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    final result = await _dioService.post(
      '/transfer',
      data: {
        'recipientId': recipientId,
        'amount': amount,
        'description': description,
      },
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        return right(transaction);
      },
    );
  }

  @override
  FutureEither<Transaction> requestMoney({
    required String senderEmail,
    required double amount,
    required String description,
  }) async {
    final result = await _dioService.post(
      '/request-money',
      data: {
        'senderEmail': senderEmail,
        'amount': amount,
        'description': description,
      },
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        return right(transaction);
      },
    );
  }

  @override
  FutureEither<String> generateReceiveQRCode() async {
    final result = await _dioService.get('/qr/generate');

    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final qrCode = data['qrCode'] as String? ?? '';
        return right(qrCode);
      },
    );
  }

  @override
  FutureEither<Map<String, dynamic>> parseQRCode(
    String qrData,
  ) async {
    final result = await _dioService.post(
      '/qr/parse',
      data: {
        'qrData': qrData,
      },
    );

    return result.fold(
      (failure) => left(failure),
      (response) {
        return right(
          response.data as Map<String, dynamic>,
        );
      },
    );
  }
}
