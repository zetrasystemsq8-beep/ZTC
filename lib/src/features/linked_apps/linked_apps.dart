// lib/src/features/linked_apps/linked_apps.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== PROVIDERS ====================

final appWalletProvider =
    FutureProvider.family<Map<String, dynamic>?, (String, String)>(
  (ref, params) async {
    final (appId, userId) = params;
    final repo = AppWalletsRepository(appId);
    return repo.getAppWallet(userId);
  },
);

// ==================== REPOSITORIES ====================

class AppWalletsRepository {
  final String appId;

  AppWalletsRepository(this.appId);

  Future<Map<String, dynamic>?> getAppWallet(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('${appId}_wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch $appId wallet: $e');
    }
  }

  Future<void> updateBalance(String userId, int balanceCents) async {
    try {
      await Supabase.instance.client
          .from('${appId}_wallets')
          .update({
            'balance_cents': balanceCents,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update $appId wallet: $e');
    }
  }

  Future<void> createAppWallet(String userId) async {
    try {
      await Supabase.instance.client
          .from('${appId}_wallets')
          .insert({
            'user_id': userId,
            'balance_cents': 0,
            'currency': 'CP',
          });
    } catch (e) {
      throw Exception('Failed to create $appId wallet: $e');
    }
  }
}

// ==================== SCREENS ====================

class LinkedAppsScreen extends HookConsumerWidget {
  const LinkedAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final apps = [
      {
        'id': 'naijalearn',
        'name': 'NaijaLearn',
        'icon': '🎓',
        'color': Colors.blue,
      },
      {
        'id': 'nigergram',
        'name': 'NigerGram',
        'icon': '📸',
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send to Apps'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 0.9,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return GestureDetector(
              onTap: () {
                context.push('/app-send/${app['id']}');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: cs.outline.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      app['icon'] as String,
                      style: TextStyle(fontSize: 48.sp),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      app['name'] as String,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Tap to send',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppSendMoneyScreen extends HookConsumerWidget {
  final String appId;

  const AppSendMoneyScreen({required this.appId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientController = useTextEditingController();
    final amountController = useTextEditingController();
    final noteController = useTextEditingController();
    final isLoading = useState(false);
    final currentStep = useState(0);
    final recipientData = useState<Map<String, dynamic>?>(null);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final appNames = {
      'naijalearn': 'NaijaLearn',
      'nigergram': 'NigerGram',
    };

    Future<void> validateRecipient() async {
      if (recipientController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter recipient ZetraID')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final result = await ref.read(
          appWalletProvider((appId, recipientController.text)).future,
        );

        if (result != null) {
          recipientData.value = result;
          currentStep.value = 1;
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User not found on ${appNames[appId]}')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSend() async {
      final amount = int.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount in cents')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) throw Exception('Not authenticated');

        // Get sender's app wallet
        final senderWallet = await ref.read(
          appWalletProvider((appId, currentUser.id)).future,
        );

        if (senderWallet == null) {
          throw Exception('You dont have a ${appNames[appId]} wallet');
        }

        final senderBalance = senderWallet['balance_cents'] as int? ?? 0;
        if (senderBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Update sender balance (deduct)
        await Supabase.instance.client
            .from('${appId}_wallets')
            .update({
              'balance_cents': senderBalance - amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', currentUser.id);

        // Update recipient balance (add)
        final recipientId = recipientData.value!['user_id'];
        final recipientBalance = (recipientData.value!['balance_cents'] as int?) ?? 0;

        await Supabase.instance.client
            .from('${appId}_wallets')
            .update({
              'balance_cents': recipientBalance + amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', recipientId);

        // Create transaction record
        await Supabase.instance.client.from('transactions').insert({
          'user_id': currentUser.id,
          'amount': amount,
          'type': 'transfer',
          'description': noteController.text.isEmpty
              ? 'Transfer to ${appNames[appId]}'
              : noteController.text,
          'recipient_email': recipientData.value!['user_id'],
          'app_type': appId,
          'status': 'completed',
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sent ${(amount / 1000).toStringAsFixed(2)} CP to ${appNames[appId]}',
              ),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Send to ${appNames[appId]}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator
            Row(
              children: [
                Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('1', style: TextStyle(color: Colors.white))),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    color: currentStep.value == 1 ? cs.primary : Colors.grey,
                  ),
                ),
                Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: currentStep.value == 1 ? cs.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: currentStep.value == 1 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            if (currentStep.value == 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recipient ZetraID', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: recipientController,
                    decoration: InputDecoration(
                      labelText: 'ZetraID (e.g., ZTR-100020)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (in cents)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : validateRecipient,
                      child: isLoading.value
                          ? const CircularProgressIndicator()
                          : const Text('Review Transfer'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm Transfer', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cs.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('To', style: tt.bodyMedium),
                            Text(
                              recipientController.text,
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount', style: tt.bodyMedium),
                            Text(
                              '${(int.parse(amountController.text) / 1000).toStringAsFixed(2)} CP',
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('App', style: tt.bodyMedium),
                            Text(
                              appNames[appId] ?? appId,
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading.value ? null : () => currentStep.value = 0,
                          child: const Text('Back'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading.value ? null : handleSend,
                          child: isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
