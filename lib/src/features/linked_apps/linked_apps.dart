// lib/src/features/linked_apps/linked_apps.dart
//
// "Fund App Balance" — top up your OWN balance in a linked app (Cent for
// NaijaLearn, the equivalent for NigerGram) directly from your ZTC CP
// wallet. This is the ONLY thing this screen does — no recipient, no
// sending to another person. Calls the same buy_app_currency RPC that
// NaijaLearn's own in-app Cent Shop "+" button already uses, so both
// entry points move real CP out of the same wallet in the same way.
//
// transfer_app_currency / resolve_app_recipient (added for the earlier
// person-to-person version of this screen) are left untouched in the
// database — unused now, but not deleted, in case a genuine "gift Cent
// to a friend" feature gets built later as its own separate thing.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== PROVIDERS ====================

final myAppBalanceProvider = FutureProvider.family<double, String>(
  (ref, appId) async {
    final repo = AppWalletsRepository(appId);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 0.0;
    return repo.getBalance(userId);
  },
);

final myCpBalanceProvider = FutureProvider<double>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0.0;
  final wallet = await client.from('wallets').select('balance').eq('user_id', userId).maybeSingle();
  return (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
});

// ==================== REPOSITORY ====================

class AppWalletsRepository {
  final String appId;

  AppWalletsRepository(this.appId);

  SupabaseClient get _client => Supabase.instance.client;

  /// Reads the signed-in user's balance for this app.
  Future<double> getBalance(String userId) async {
    try {
      final row = await _client
          .from('app_currency_balances')
          .select('balance')
          .eq('user_id', userId)
          .eq('app_id', appId)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));

      return (row?['balance'] as num?)?.toDouble() ?? 0.0;
    } on TimeoutException {
      throw Exception('This is taking too long — please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to fetch $appId balance: $e');
    }
  }

  /// Converts CP from the signed-in user's own ZTC wallet into this
  /// app's currency, credited to their OWN balance for this app. No
  /// recipient — this always funds the caller's own account.
  Future<void> topUp({required double cpAmount}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in.');

      final wallet = await _client
          .from('wallets')
          .select('id')
          .eq('user_id', userId)
          .single()
          .timeout(const Duration(seconds: 12));

      final result = await _client.rpc('buy_app_currency', params: {
        'p_wallet_id': wallet['id'],
        'p_app_id': appId,
        'p_cent_amount': cpAmount,
      }).timeout(const Duration(seconds: 12));

      if (!(result is Map && result['success'] == true)) {
        throw Exception('Top-up failed');
      }
    } on TimeoutException {
      throw Exception('This is taking too long — please check your connection and try again.');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
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
      {'id': 'naijalearn', 'name': 'NaijaLearn', 'icon': '🎓', 'color': Colors.blue},
      {'id': 'nigergram', 'name': 'NigerGram', 'icon': '📸', 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund App Balance'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
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
              onTap: () => context.push('/app-topup/${app['id']}'),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: cs.outline.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(app['icon'] as String, style: TextStyle(fontSize: 48.sp)),
                    SizedBox(height: 12.h),
                    Text(app['name'] as String, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 8.h),
                    Text('Tap to top up', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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

  static const List<double> _presetAmounts = [1, 5, 10, 25, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customController = useTextEditingController();
    final selectedAmount = useState<double?>(null);
    final isLoading = useState(false);
    final errorText = useState<String?>(null);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appNames = {'naijalearn': 'NaijaLearn', 'nigergram': 'NigerGram'};
    final repo = AppWalletsRepository(appId);
    final cpBalanceAsync = ref.watch(myCpBalanceProvider);

    Future<void> confirmTopUp() async {
      final amount = selectedAmount.value ?? double.tryParse(customController.text);
      if (amount == null || amount <= 0) {
        errorText.value = 'Choose or enter a valid amount.';
        return;
      }

      isLoading.value = true;
      errorText.value = null;

      try {
        await repo.topUp(cpAmount: amount);
        ref.invalidate(myAppBalanceProvider(appId));
        ref.invalidate(myCpBalanceProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${appNames[appId]} balance topped up successfully')),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) Navigator.pop(context);
          });
        }
      } catch (e) {
        errorText.value = e.toString().replaceFirst('Exception: ', '');
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Up ${appNames[appId]}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cpBalanceAsync.when(
              data: (cp) => Text('Your ZTC balance: ${cp.toStringAsFixed(2)} CP', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              loading: () => const SizedBox(height: 20, child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            SizedBox(height: 24.h),
            Text('Choose an amount (CP)', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: _presetAmounts.map((amt) {
                final selected = selectedAmount.value == amt;
                return ChoiceChip(
                  label: Text('${amt.toStringAsFixed(0)} CP'),
                  selected: selected,
                  onSelected: (_) {
                    selectedAmount.value = amt;
                    customController.clear();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: customController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => selectedAmount.value = null,
              decoration: InputDecoration(
                labelText: 'Or enter a custom amount (CP)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
            ),
            if (errorText.value != null) ...[
              SizedBox(height: 12.h),
              Text(errorText.value!, style: TextStyle(color: cs.error)),
            ],
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : confirmTopUp,
                child: isLoading.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Top Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
