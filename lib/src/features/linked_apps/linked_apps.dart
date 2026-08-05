// lib/src/features/linked_apps/linked_apps.dart
//
// "Send to Apps" — send CP and/or Cent to another Zetra user,
// scoped to a chosen app. Both currencies can be sent in a single transaction.
//
// Self-send rule:
// - Sending Cent to yourself is valid — it's how a user funds their
//   own balance inside that app (topping up NaijaLearn Cent, say).
// - Sending CP to yourself is ALSO valid now, and for the same reason:
//   since sendCp calls send_cp_to_app_currency (not a raw wallet-to-
//   wallet transfer), sending CP "to yourself" is exactly how someone
//   converts their own CP into their own app-currency balance for the
//   first time. Blocking it would make that conversion impossible.
//
// Recipient lookup uses search_profiles (SECURITY DEFINER RPC) instead
// of querying `profiles` directly — a direct query is blocked by RLS
// for anyone else's row and was the original cause of the infinite
// spinner. Every network call has a 15s timeout so a hang always
// surfaces as a visible error instead of an endless spinner.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== SHARED MODELS ====================

class RecipientMatch {
  final String userId;
  final String zetraId;
  final String? zetramail;
  final String? username;
  final String? fullName;

  const RecipientMatch({
    required this.userId,
    required this.zetraId,
    this.zetramail,
    this.username,
    this.fullName,
  });

  String get displayLabel => fullName ?? username ?? zetramail ?? zetraId;
}

// ==================== REPOSITORY ====================

class AppWalletsRepository {
  final String appId;

  AppWalletsRepository(this.appId);

  SupabaseClient get _client => Supabase.instance.client;

  static const _timeout = Duration(seconds: 15);

  /// Live search across Zetra ID, ZetraMail, username, and name — same
  /// safe search_profiles RPC used by ZTC's own Send Money screen.
  Future<List<RecipientMatch>> searchRecipients(String query) async {
    if (query.trim().isEmpty) return [];

    final data = await _client
        .rpc('search_profiles', params: {'search_query': query})
        .timeout(_timeout);

    return (data as List)
        .map((row) => RecipientMatch(
              userId: row['id'] as String,
              zetraId: row['zetra_id'] as String,
              zetramail: row['zetramail'] as String?,
              username: row['username'] as String?,
              fullName: row['full_name'] as String?,
            ))
        .toList();
  }

  /// This app's currency balance for a user. Returns 0 if no row yet.
  Future<double> getBalance(String userId) async {
    final row = await _client
        .from('app_currency_balances')
        .select('balance')
        .eq('user_id', userId)
        .eq('app_id', appId)
        .maybeSingle()
        .timeout(_timeout);

    return (row?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// The signed-in user's own wallet id. Kept for anything else in the
  /// app that still needs it — no longer used by sendCp itself.
  Future<String> getMyWalletId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final row = await _client
        .from('wallets')
        .select('id')
        .eq('user_id', userId)
        .single()
        .timeout(_timeout);

    return row['id'] as String;
  }

  /// Sends this app's own currency (e.g. NaijaLearn Cent) to another
  /// user, or to yourself (self-funding), via the atomic
  /// transfer_app_currency RPC. Self-recipient is valid here.
  Future<void> sendAppCurrency({
    required String recipientUserId,
    required double unitAmount,
    String? note,
  }) async {
    final result = await _client.rpc('transfer_app_currency', params: {
      'p_app_id': appId,
      'p_recipient_user_id': recipientUserId,
      'p_unit_amount': unitAmount,
      'p_note': note,
    }).timeout(_timeout);

    if (!(result is Map && result['success'] == true)) {
      throw Exception('Transfer failed');
    }
  }

  /// Sends CP, converted into THIS app's own currency for the
  /// recipient — via send_cp_to_app_currency, which debits the
  /// sender's real CP wallet and credits the recipient's
  /// app_currency_balances row for [appId], using that app's own
  /// registered conversion rate (cents_per_unit).
  ///
  /// Sending to yourself is valid and intentional — that's how a user
  /// converts their own CP into their own app-currency balance for
  /// the first time.
  ///
  /// This replaced a call to transfer_cp, which only moved CP between
  /// regular wallets and never touched app_currency_balances at all —
  /// meaning a "CP" send through an app card never actually reached
  /// the app it was sent through.
  Future<String?> sendCp({
    required String recipientUserId,
    required double cpAmount,
    String? note,
  }) async {
    try {
      final result = await _client.rpc('send_cp_to_app_currency', params: {
        'p_app_id': appId,
        'p_recipient_user_id': recipientUserId,
        'p_cp_amount': cpAmount,
        'p_note': (note?.isEmpty ?? true) ? null : note,
      }).timeout(_timeout);

      if (result is Map && result['success'] == true) return null;
      return 'Transfer failed';
    } on PostgrestException catch (e) {
      return e.message;
    } on TimeoutException {
      return 'Request timed out. Please try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }
}

final myAppBalanceProvider = FutureProvider.family<double, String>(
  (ref, appId) async {
    final repo = AppWalletsRepository(appId);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 0.0;
    return repo.getBalance(userId);
  },
);

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
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(app['icon'] as String, style: TextStyle(fontSize: 48.sp)),
                    SizedBox(height: 12.h),
                    Text(app['name'] as String, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 8.h),
                    Text('Tap to send', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
    final searchController = useTextEditingController();
    final cpController = useTextEditingController();
    final centController = useTextEditingController();
    final noteController = useTextEditingController();
    final isLoading = useState(false);
    final currentStep = useState(0);

    final selectedRecipient = useState<RecipientMatch?>(null);
    final searchResults = useState<List<RecipientMatch>>([]);
    final isSearching = useState(false);
    final debounce = useRef<Timer?>(null);
    final error = useState<String?>(null);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appNames = {'naijalearn': 'NaijaLearn', 'nigergram': 'NigerGram'};
    final repo = AppWalletsRepository(appId);

    void onSearchChanged(String query) {
      if (selectedRecipient.value != null) {
        selectedRecipient.value = null;
      }
      error.value = null;

      debounce.value?.cancel();
      if (query.trim().isEmpty) {
        searchResults.value = [];
        return;
      }

      debounce.value = Timer(const Duration(milliseconds: 350), () async {
        isSearching.value = true;
        try {
          final results = await repo.searchRecipients(query);
          searchResults.value = results;
        } catch (_) {
          searchResults.value = [];
        } finally {
          isSearching.value = false;
        }
      });
    }

    void selectRecipient(RecipientMatch match) {
      selectedRecipient.value = match;
      searchController.text = match.displayLabel;
      searchResults.value = [];
    }

    Future<void> handleSend() async {
      final recipient = selectedRecipient.value;
      if (recipient == null) {
        error.value = 'Select a recipient from the search results';
        return;
      }

      final cpAmount = double.tryParse(cpController.text) ?? 0;
      final centAmount = double.tryParse(centController.text) ?? 0;

      if (cpAmount <= 0 && centAmount <= 0) {
        error.value = 'Enter at least one amount (CP or Cent)';
        return;
      }

      isLoading.value = true;
      error.value = null;

      try {
        // Send CP first (if amount > 0)
        if (cpAmount > 0) {
          final sendError = await repo.sendCp(
            recipientUserId: recipient.userId,
            cpAmount: cpAmount,
            note: noteController.text.isEmpty ? null : noteController.text,
          );
          if (sendError != null) {
            throw Exception(sendError);
          }
        }

        // Then send Cent (if amount > 0)
        if (centAmount > 0) {
          await repo.sendAppCurrency(
            recipientUserId: recipient.userId,
            unitAmount: centAmount,
            note: noteController.text.isEmpty ? null : noteController.text,
          );
        }

        if (context.mounted) {
          String amountSummary = '';
          if (cpAmount > 0) amountSummary += '$cpAmount CP';
          if (centAmount > 0) {
            if (amountSummary.isNotEmpty) amountSummary += ' and ';
            amountSummary += '$centAmount Cent';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sent $amountSummary to ${appNames[appId]}')),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) Navigator.pop(context);
          });
        }
      } on TimeoutException {
        error.value = 'Request timed out. Please try again.';
      } catch (e) {
        error.value = e.toString().replaceFirst('Exception: ', '');
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
                  decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
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
                    child: Text('2', style: TextStyle(color: currentStep.value == 1 ? Colors.white : Colors.grey)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            if (currentStep.value == 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recipient', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      labelText: 'Search Zetra ID, ZetraMail, or name',
                      hintText: 'Start typing to search',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching.value
                          ? Padding(
                              padding: EdgeInsets.all(12.w),
                              child: SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (selectedRecipient.value != null
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null),
                    ),
                  ),
                  if (searchResults.value.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: cs.outline.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: searchResults.value.map((match) {
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(match.displayLabel),
                            subtitle: Text(match.zetraId),
                            onTap: () => selectRecipient(match),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Text('Amount', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  Text('Send CP', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: cpController,
                    decoration: InputDecoration(
                      labelText: 'Amount (CP)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Converts your CP into ${appNames[appId]}'s currency. You can send to yourself to fund your own balance from CP.",
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  SizedBox(height: 16.h),
                  Text('Send Cent', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: centController,
                    decoration: InputDecoration(
                      labelText: 'Amount (Cent)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.savings_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Sends directly into the recipient's ${appNames[appId]} balance. You can send to yourself to fund your own balance.",
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                  if (error.value != null) ...[
                    SizedBox(height: 12.h),
                    Text(error.value!, style: TextStyle(color: cs.error)),
                  ],
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedRecipient.value == null) {
                          error.value = 'Select a recipient from the search results';
                          return;
                        }
                        final cpAmount = double.tryParse(cpController.text) ?? 0;
                        final centAmount = double.tryParse(centController.text) ?? 0;
                        if (cpAmount <= 0 && centAmount <= 0) {
                          error.value = 'Enter at least one amount (CP or Cent)';
                          return;
                        }
                        error.value = null;
                        currentStep.value = 1;
                      },
                      child: const Text('Review Transfer'),
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
                            Text(selectedRecipient.value?.displayLabel ?? '', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Zetra ID', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            Text(selectedRecipient.value?.zetraId ?? '', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        if ((double.tryParse(cpController.text) ?? 0) > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CP Amount', style: tt.bodyMedium),
                              Text(
                                '${cpController.text} CP',
                                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                        ],
                        if ((double.tryParse(centController.text) ?? 0) > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cent Amount', style: tt.bodyMedium),
                              Text(
                                '${centController.text} Cent',
                                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('App', style: tt.bodyMedium),
                            Text(appNames[appId] ?? appId, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (error.value != null) ...[
                    SizedBox(height: 12.h),
                    Text(error.value!, style: TextStyle(color: cs.error)),
                  ],
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
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
