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
  FutureEither<List<User>> searchUsers({required String query}) async {
    try {
      final response = await _dioService.get(
        '/users/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final users = data
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(users);
      }

      return left(ServerFailure('Search failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<User> getUserByEmail(String email) async {
    try {
      final response = await _dioService.get('/users/email/$email');

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        return right(user);
      }

      return left(ServerFailure('User not found'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<User> getUserById(String id) async {
    try {
      final response = await _dioService.get('/users/$id');

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        return right(user);
      }

      return left(ServerFailure('User not found'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<List<User>> getRecentRecipients({int limit = 10}) async {
    try {
      final response = await _dioService.get(
        '/users/recipients',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final users = data
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(users);
      }

      return left(ServerFailure('Failed to fetch recipients'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> transfer({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    try {
      final response = await _dioService.post(
        '/transfer',
        data: {
          'recipientId': recipientId,
          'amount': amount,
          'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }

      return left(ServerFailure('Transfer failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Transaction> requestMoney({
    required String senderEmail,
    required double amount,
    required String description,
  }) async {
    try {
      final response = await _dioService.post(
        '/request-money',
        data: {
          'senderEmail': senderEmail,
          'amount': amount,
          'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = TransactionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return right(transaction);
      }

      return left(ServerFailure('Request failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<String> generateReceiveQRCode() async {
    try {
      final response = await _dioService.get('/qr/generate');

      if (response.statusCode == 200) {
        final qrCode = response.data['qrCode'] as String? ?? '';
        return right(qrCode);
      }

      return left(ServerFailure('Failed to generate QR code'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<Map<String, dynamic>> parseQRCode(String qrData) async {
    try {
      final response = await _dioService.post(
        '/qr/parse',
        data: {'qrData': qrData},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return right(data);
      }

      return left(ServerFailure('Invalid QR code'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
