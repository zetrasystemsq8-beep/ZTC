import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ztc_bank/src/features/wallet/presentation/providers/wallet_provider.dart';

void _showAppSnackBar(
  BuildContext context, {
  required String message,
  _SnackType type = _SnackType.info,
}) {
  final theme = Theme.of(context);
  final Color bg;
  final IconData icon;

  switch (type) {
    case _SnackType.success:
      bg = const Color(0xFF1E7C4A);
      icon = Icons.check_circle_rounded;
      break;
    case _SnackType.error:
      bg = const Color(0xFFB3261E);
      icon = Icons.error_rounded;
      break;
    case _SnackType.info:
      bg = theme.colorScheme.primary;
      icon = Icons.info_rounded;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      elevation: 6,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _SnackType { success, error, info }

class _RecipientMatch {
  final String id;
  final String zetraId;
  final String? zetramail;
  final String? username;
  final String? fullName;

  const _RecipientMatch({
    required this.id,
    required this.zetraId,
    this.zetramail,
    this.username,
    this.fullName,
  });

  String get displayLabel => fullName ?? username ?? zetramail ?? zetraId;
  String get displaySubLabel => zetraId;
}

Future<List<_RecipientMatch>> _searchRecipients(String query) async {
  if (query.trim().isEmpty) return [];

  final data = await Supabase.instance.client.rpc(
    'search_profiles',
    params: {'search_query': query},
  );

  return (data as List)
      .map((row) => _RecipientMatch(
            id: row['id'] as String,
            zetraId: row['zetra_id'] as String,
            zetramail: row['zetramail'] as String?,
            username: row['username'] as String?,
            fullName: row['full_name'] as String?,
          ))
      .toList();
}

class SendMoneyScreen extends HookConsumerWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final cpController = useTextEditingController();
    final centController = useTextEditingController();
    final noteController = useTextEditingController();
    final isLoading = useState(false);
    final currentStep = useState(0); // 0 = enter details, 1 = confirm

    final selectedRecipient = useState<_RecipientMatch?>(null);
    final searchResults = useState<List<_RecipientMatch>>([]);
    final isSearching = useState(false);
    final debounce = useRef<Timer?>(null);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    void onSearchChanged(String query) {
      if (selectedRecipient.value != null) {
        selectedRecipient.value = null;
      }

      debounce.value?.cancel();
      if (query.trim().isEmpty) {
        searchResults.value = [];
        return;
      }

      debounce.value = Timer(const Duration(milliseconds: 350), () async {
        isSearching.value = true;
        try {
          final results = await _searchRecipients(query);
          searchResults.value = results;
        } catch (_) {
          searchResults.value = [];
        } finally {
          isSearching.value = false;
        }
      });
    }

    void selectRecipient(_RecipientMatch match) {
      selectedRecipient.value = match;
      searchController.text = match.displayLabel;
      searchResults.value = [];
    }

    /// Carries any Cent overflow (1000+) into the CP field live, so
    /// typing "1500" in Cent instantly becomes "1" CP + "500" Cent.
    /// CP and Cent are ONE currency at two denominations — this keeps
    /// the split always valid, never letting Cent alone imply a larger
    /// value than what actually shows on screen.
    void onCentChanged(String value) {
      final raw = int.tryParse(value) ?? 0;
      if (raw >= 1000) {
        final overflowCp = raw ~/ 1000;
        final remainder = raw % 1000;
        final currentCp = int.tryParse(cpController.text) ?? 0;
        cpController.text = (currentCp + overflowCp).toString();
        centController.text = remainder.toString();
        centController.selection = TextSelection.collapsed(offset: centController.text.length);
      }
    }

    /// Combines the CP field and Cent field into one total CP value
    /// (e.g. 2 CP + 500 Cent = 2.5 CP) — the only shape the backend
    /// transfer_cp RPC accepts.
    double totalCpAmount() {
      final cp = int.tryParse(cpController.text) ?? 0;
      final cent = int.tryParse(centController.text) ?? 0;
      return cp + (cent / 1000.0);
    }

    Future<void> handleSend() async {
      final recipient = selectedRecipient.value;
      if (recipient == null) {
        _showAppSnackBar(context, message: 'Select a recipient from the search results', type: _SnackType.error);
        return;
      }

      final cpAmount = totalCpAmount();
      if (cpAmount <= 0) {
        _showAppSnackBar(context, message: 'Enter a valid amount', type: _SnackType.error);
        return;
      }

      isLoading.value = true;

      final errorMessage = await ref.read(walletProvider.notifier).send(
            cpAmount,
            recipient.zetraId,
            noteController.text.isEmpty ? 'Transfer' : noteController.text,
          );

      isLoading.value = false;

      if (context.mounted) {
        if (errorMessage == null) {
          _showAppSnackBar(context, message: 'Transfer sent successfully!', type: _SnackType.success);
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) Navigator.pop(context);
          });
        } else {
          _showAppSnackBar(context, message: errorMessage, type: _SnackType.error);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
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
                  child: Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                        fontWeight: FontWeight.bold,
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
                  Text(
                    'Recipient Details',
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      labelText: 'Search Zetra ID, ZetraMail, or name',
                      hintText: 'Start typing to search',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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
                            subtitle: Text(match.displaySubLabel),
                            onTap: () => selectRecipient(match),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Text(
                    'Amount',
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CP', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: cpController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cent', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: centController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: onCentChanged,
                              decoration: InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Builder(builder: (context) {
                    final cp = int.tryParse(cpController.text) ?? 0;
                    final cent = int.tryParse(centController.text) ?? 0;
                    if (cp == 0 && cent == 0) return const SizedBox.shrink();
                    return Text(
                      'Total: $cp CP $cent Cent',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                    );
                  }),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(Icons.note_outlined),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedRecipient.value == null) {
                          _showAppSnackBar(context, message: 'Select a recipient from the search results', type: _SnackType.error);
                          return;
                        }
                        if (totalCpAmount() <= 0) {
                          _showAppSnackBar(context, message: 'Enter a valid amount', type: _SnackType.error);
                          return;
                        }
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
                  Text(
                    'Confirm Transfer',
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
                            Text('Recipient', style: tt.bodyMedium),
                            Text(
                              selectedRecipient.value?.displayLabel ?? '',
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Zetra ID', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            Text(
                              selectedRecipient.value?.zetraId ?? '',
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount', style: tt.bodyMedium),
                            Builder(builder: (context) {
                              final cp = int.tryParse(cpController.text) ?? 0;
                              final cent = int.tryParse(centController.text) ?? 0;
                              return Text(
                                '$cp CP $cent Cent',
                                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              );
                            }),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Note', style: tt.bodyMedium),
                            Text(
                              noteController.text.isEmpty ? 'None' : noteController.text,
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
                          onPressed: isLoading.value
                              ? null
                              : () => currentStep.value = 0,
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
