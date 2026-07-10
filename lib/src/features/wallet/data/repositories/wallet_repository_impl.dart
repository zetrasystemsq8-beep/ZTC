import 'package:flutter_clean_architecture/core/di/injection.dart';
import 'package:flutter_clean_architecture/core/network/dio_service.dart';
import 'package:flutter_clean_architecture/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/usecases/deposit_usecase.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/usecases/get_recent_transactions_usecase.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/usecases/receive_usecase.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/usecases/send_usecase.dart';
import 'package:flutter_clean_architecture/features/wallet/domain/usecases/withdraw_usecase.dart';
import 'package:flutter_clean_architecture/features/wallet/presentation/providers/wallet_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(DioService.instance);
});

final getWalletUseCaseProvider = Provider<GetWalletUseCase>((ref) {
  return GetWalletUseCase(ref.read(walletRepositoryProvider));
});

final getRecentTransactionsUseCaseProvider = Provider<GetRecentTransactionsUseCase>((ref) {
  return GetRecentTransactionsUseCase(ref.read(walletRepositoryProvider));
});

final depositUseCaseProvider = Provider<DepositUseCase>((ref) {
  return DepositUseCase(ref.read(walletRepositoryProvider));
});

final withdrawUseCaseProvider = Provider<WithdrawUseCase>((ref) {
  return WithdrawUseCase(ref.read(walletRepositoryProvider));
});

final sendUseCaseProvider = Provider<SendUseCase>((ref) {
  return SendUseCase(ref.read(walletRepositoryProvider));
});

final receiveUseCaseProvider = Provider<ReceiveUseCase>((ref) {
  return ReceiveUseCase(ref.read(walletRepositoryProvider));
});

final walletNotifierProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(
    getWalletUseCase: ref.read(getWalletUseCaseProvider),
    getRecentTransactionsUseCase: ref.read(getRecentTransactionsUseCaseProvider),
    depositUseCase: ref.read(depositUseCaseProvider),
    withdrawUseCase: ref.read(withdrawUseCaseProvider),
    sendUseCase: ref.read(sendUseCaseProvider),
    receiveUseCase: ref.read(receiveUseCaseProvider),
  );
});
