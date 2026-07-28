import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';
import 'package:ztc_bank/src/features/send_receive/presentation/providers/send_receive_provider.dart';
import 'package:ztc_bank/src/features/send_receive/presentation/widgets/send_receive_widgets.dart';

class SendMoneyScreen extends HookConsumerWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final amountController = useTextEditingController();
    final noteController = useTextEditingController();
    final currentStep = useState<int>(0);
    final isLoading = useState<bool>(false);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final searchResults = ref.watch(searchUsersProvider);
    final selectedRecipient = ref.watch(selectedRecipientProvider);
    final transferAsyncValue = ref.watch(transferProvider);

    void handleSearch(String query) {
      ref.read(searchUsersProvider.notifier).searchUsers(query);
    }

    void handleSelectRecipient(User user) {
      ref.read(selectedRecipientProvider.notifier).state = user;
      currentStep.value = 1;
    }

    Future<void> handleTransfer() async {
      if (selectedRecipient == null || amountController.text.isEmpty) {
        showToast(context, message: 'Please fill all fields', status: 'error');
        return;
      }

      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        showToast(context, message: 'Enter a valid amount', status: 'error');
        return;
      }

      isLoading.value = true;
      await ref.read(transferProvider.notifier).processTransfer(
        recipientId: selectedRecipient.id,
        amount: amount,
        description: noteController.text,
      );
      isLoading.value = false;

      if (context.mounted) {
        transferAsyncValue.whenData((transaction) {
          showToast(context, message: 'Transfer successful', status: 'success');
          Future.delayed(const Duration(seconds: 1), () {
            context.pop();
          });
        });
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(title: 'Send Money'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Indicator
              _StepIndicator(currentStep: currentStep.value, totalSteps: 2),
              SizedBox(height: AppSpacing.xl.h),

              // Step 1: Select Recipient
              if (currentStep.value == 0)
                _SelectRecipientStep(
                  searchController: searchController,
                  searchResults: searchResults,
                  selectedRecipient: selectedRecipient,
                  onSearch: handleSearch,
                  onSelectRecipient: handleSelectRecipient,
                )
              else
                _ConfirmTransferStep(
                  selectedRecipient: selectedRecipient,
                  amountController: amountController,
                  noteController: noteController,
                  isLoading: isLoading.value,
                  onTransfer: handleTransfer,
                  onBackPressed: () => currentStep.value = 0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 40.w,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: cs.onPrimary, size: 20.sp)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (index < totalSteps - 1)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                    child: Container(
                      height: 2,
                      color: isCompleted ? cs.primary : cs.surfaceContainerHighest,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SelectRecipientStep extends StatelessWidget {
  final TextEditingController searchController;
  final AsyncValue<List<User>> searchResults;
  final User? selectedRecipient;
  final ValueChanged<String> onSearch;
  final ValueChanged<User> onSelectRecipient;

  const _SelectRecipientStep({
    required this.searchController,
    required this.searchResults,
    required this.selectedRecipient,
    required this.onSearch,
    required this.onSelectRecipient,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who are you sending to?',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.md.h),
        RecipientSearchBar(
          onSearch: onSearch,
          onClear: () {
            searchController.clear();
            onSearch('');
          },
        ),
        SizedBox(height: AppSpacing.lg.h),
        searchResults.when(
          loading: () => const AppLoading(),
          error: (error, stack) => AppErrorWidget(
            message: error.toString(),
            onRetry: () => onSearch(searchController.text),
          ),
          data: (users) {
            if (users.isEmpty && searchController.text.isNotEmpty) {
              return AppEmptyState(
                icon: IconsaxPlusLinear.user,
                title: 'No users found',
                subtitle: 'Try searching with a different email or name',
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (context, index) => SizedBox(height: AppSpacing.md.h),
              itemBuilder: (context, index) {
                final user = users[index];
                return RecipientCard(
                  user: user,
                  isSelected: selectedRecipient?.id == user.id,
                  onSelect: () => onSelectRecipient(user),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ConfirmTransferStep extends StatelessWidget {
  final User? selectedRecipient;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final bool isLoading;
  final VoidCallback onTransfer;
  final VoidCallback onBackPressed;

  const _ConfirmTransferStep({
    required this.selectedRecipient,
    required this.amountController,
    required this.noteController,
    required this.isLoading,
    required this.onTransfer,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter amount & details',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.lg.h),
        TransferAmountInput(
          controller: amountController,
          label: 'Amount',
          validator: (value) {
            if (AppUtils.isBlank(value)) return 'Amount is required';
            final amount = double.tryParse(value!);
            if (amount == null || amount <= 0) return 'Enter a valid amount';
            return null;
          },
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppTextField(
          controller: noteController,
          label: 'Note (Optional)',
          hint: 'Add a note for this transfer',
          prefixIcon: const Icon(IconsaxPlusBold.note),
          maxLines: 3,
        ),
        SizedBox(height: AppSpacing.xl.h),
        if (selectedRecipient != null)
          ListenableBuilder(
            listenable: Listenable.merge([amountController, noteController]),
            builder: (context, _) => TransferSummaryCard(
              recipientName: selectedRecipient!.name ?? selectedRecipient!.email,
              recipientEmail: selectedRecipient!.email,
              amount: double.tryParse(amountController.text) ?? 0,
              description: noteController.text.isEmpty ? 'No note' : noteController.text,
            ),
          ),
        SizedBox(height: AppSpacing.xl.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                variant: ButtonVariant.outline,
                onPressed: isLoading ? null : onBackPressed,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: AppButton(
                label: 'Send',
                isLoading: isLoading,
                onPressed: isLoading ? null : onTransfer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
