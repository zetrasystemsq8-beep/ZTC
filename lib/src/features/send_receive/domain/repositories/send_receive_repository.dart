import 'package:ztc_bank/src/utils/utils.dart';
import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

abstract class SendReceiveRepository {
  /// Search for users by email or name
  FutureEither<List<User>> searchUsers({required String query});

  /// Get user by email
  FutureEither<User> getUserByEmail(String email);

  /// Get user by ID
  FutureEither<User> getUserById(String id);

  /// Get list of recent recipients
  FutureEither<List<User>> getRecentRecipients({int limit = 10});

  /// Process money transfer
  FutureEither<Transaction> transfer({
    required String recipientId,
    required double amount,
    required String description,
  });

  /// Process money request
  FutureEither<Transaction> requestMoney({
    required String senderEmail,
    required double amount,
    required String description,
  });

  /// Generate QR code data for receiving money
  FutureEither<String> generateReceiveQRCode();

  /// Parse QR code data to extract user/transaction info
  FutureEither<Map<String, dynamic>> parseQRCode(String qrData);
}
