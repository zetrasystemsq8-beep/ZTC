import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/utils/typedefs.dart';

abstract class SendReceiveRepository {
  FutureEither<List<User>> searchUsers({
    required String query,
  });

  FutureEither<User> getUserByEmail(String email);

  FutureEither<User> getUserById(String id);

  FutureEither<List<User>> getRecentRecipients({
    int limit = 10,
  });

  FutureEither<Transaction> transfer({
    required String recipientId,
    required double amount,
    required String description,
  });

  FutureEither<Transaction> requestMoney({
    required String senderEmail,
    required double amount,
    required String description,
  });

  FutureEither<String> generateReceiveQRCode();

  FutureEither<Map<String, dynamic>> parseQRCode(
    String qrData,
  );
}
