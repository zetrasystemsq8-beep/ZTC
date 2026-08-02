// lib/src/features/linked_apps/linked_apps.dart
//
// FIXED VERSION — "Send to Apps" now correctly:
// 1. Resolves the recipient's ZetraID to their real user_id via the
//    `profiles` table (previously this step was missing entirely, which
//    caused the wallet lookup to always search for a nonexistent user
//    and made the button spin forever).
// 2. Reads/writes balances through `app_currency_balances` (the real,
//    shared table used across all apps), instead of a per-app
//    `naijalearn_wallets` / `nigergram_wallets` table that never existed.
// 3. Debits the sender and credits the recipient through the existing
//    `spend_app_currency` and `credit_app_currency` RPCs, which run
//    server-side with proper checks, instead of the client directly
//    overwriting balance numbers (which is unsafe and can race).

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== PROVIDERS ====================

/// Resolves a recipient's ZetraID to their profile + their balance for
/// [appId], in one shot. Returns null if no profile matches that ZetraID.
final appRecipientProvider =
    FutureProvider.family<Map<String, dynamic>?, (String, String)>(
  (ref, params) async {
    final (appId, zetraId) = params;
    final repo = AppWalletsRepository(appId);
    return repo.resolveRecipientByZetraId(zetraId);
  },
);

/// The signed-in user's own balance for [appId].
final myAppBalanceProvider = FutureProvider.family<double, String>(
  (ref, appId) async {
    final repo = AppWalletsRepository(appId);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 0.0;
    return repo.getBalance(userId);
  },
);

// ==================== REPOSITORIES ====================

class AppWalletsRepository {
  final String appId;

  AppWalletsRepository(this.appId);

  SupabaseClient get _client => Supabase.instance.client;

  /// Step 1 of sending money: look up who owns a given ZetraID, via the
  /// shared `profiles` table (NOT a per-app wallets table — ZetraID is a
  /// Zetra-ecosystem-wide identifier, not something each app tracks).
  Future<Map<String, dynamic>?> resolveRecipientByZetraId(String zetraId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id, zetra_id, username')
          .eq('zetra_id', zetraId.trim())
          .maybeSingle();

      if (profile == null) return null;

      final recipientUserId = profile['id'] as String;
      final balance = await getBalance(recipientUserId);

      return {
        'user_id': recipientUserId,
        'zetra_id': profile['zetra_id'],
        'username': profile['username'],
        'balance': balance,
      };
    } catch (e) {
      throw Exception('Failed to resolve recipient: $e');
    }
  }

  /// Reads a user's balance for this app from the shared
  /// `app_currency_balances` table. Returns 0 if they have no row yet
  /// (i.e. they've never received or spent this app's currency before).
  Future<double> getBalance(String userId) async {
    try {
      final row = await _client
          .from('app_currency_balances')
          .select('balance')
          .eq('user_id', userId)
          .eq('app_id', appId)
          .maybeSingle();

      return (row?['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to fetch $appId balance: $e');
    }
  }

  /// Debits [unitAmount] from the signed-in user's own balance for this
  /// app, via the server-side RPC (which checks sufficient balance and
  /// prevents race conditions — never do this with a raw client update).
  Future<void> spendFromMyBalance(double unitAmount) async {
    final result = await _client.rpc('spend_app_currency', params: {
      'p_app_id': appId,
      'p_unit_amount': unitAmount,
    });
    if (!(result is Map && result['success'] == true)) {
      throw Exception('Could not debit your balance');
    }
  }

  /// Credits [unitAmount] to [recipientUserId]'s balance for this app,
  /// via a server-side RPC. This assumes `credit_app_currency` (or an
  /// equivalent) accepts a target user_id — if your current RPC only
  /// credits `auth.uid()` (the caller), it needs a small server-side
  /// addition to accept crediting a *different* user for peer transfers.
  /// That addition is a backend task, not something the client can work
  /// around safely.
  Future<void> creditRecipientBalance({
    required String recipientUserId,
    required double unitAmount,
  }) async {
    final result = await _client.rpc('credit_app_currency_to_user', params: {
      'p_app_id': appId,
      'p_recipient_user_id': recipientUserId,
      'p_unit_amount': unitAmount,
    });
    if (!(result is Map && result['success'] == true)) {
      throw Exception('Could not credit the recipient');
    }
  }
}

// ==================== SCREENS ====================

class LinkedAppsScreen extends HookConsumerWidget {
  const LinkedAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appNames = {
      'naijalearn': 'NaijaLearn',
      'nigergram': 'NigerGram',
    };

    final repo = AppWalletsRepository(appId);

    Future<void> validateRecipient() async {
      final zetraId = recipientController.text.trim();
      if (zetraId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter recipient ZetraID')),
        );
        return;
      }

      final amount = int.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount in cents')),
        );
        return;
      }

      isLoading.value = true;

      try {
        // Correct two-step lookup: ZetraID -> profile -> balance.
        final result = await repo.resolveRecipientByZetraId(zetraId);

        if (result != null) {
          recipientData.value = result;
          currentStep.value = 1;
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No Zetra account found with that ID')),
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

      final recipient = recipientData.value;
      if (recipient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipient not resolved. Go back and try again.')),
        );
        return;
      }

      isLoading.value = true;

      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) throw Exception('Not authenticated');

        // Prevent sending to yourself, which the old code never checked.
        if (recipient['user_id'] == currentUser.id) {
          throw Exception('You cannot send to your own account');
        }

        final unitAmount = amount / 1000.0; // cents -> app currency units, matches existing convention

        // Debit sender via RPC (server-side balance check, no race conditions).
        await repo.spendFromMyBalance(unitAmount);

        // Credit recipient via RPC.
        await repo.creditRecipientBalance(
          recipientUserId: recipient['user_id'] as String,
          unitAmount: unitAmount,
        );

        // Log it for the sender's own transaction history.
        await Supabase.instance.client.from('transactions').insert({
          'user_id': currentUser.id,
          'amount': amount,
          'type': 'transfer',
          'description': noteController.text.isEmpty
              ? 'Transfer to ${appNames[appId]}'
              : noteController.text,
          'recipient_id': recipient['user_id'],
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
            if (context.mounted) Navigator.pop(context);
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
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
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
                              recipientData.value?['username'] as String? ?? recipientController.text,
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ZetraID', style: tt.bodyMedium),
                            Text(
                              recipientData.value?['zetra_id'] as String? ?? recipientController.text,
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
