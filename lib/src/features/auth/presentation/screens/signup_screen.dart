import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/auth/presentation/providers/auth_provider.dart';

class SignupScreen extends HookConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);

    final isLoading = ref.watch(authControllerProvider);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleSignup() async {
      if (!(formKey.currentState?.validate() ?? false)) return;

      ref.read(authControllerProvider.notifier).signUp(
        context: context, 
        name: nameController.text,
        email: emailController.text, 
        password: passwordController.text,
      );
    }

    return _SignupView(
      formKey: formKey,
      nameController: nameController,
      emailController: emailController,
      passwordController: passwordController,
      confirmPasswordController: confirmPasswordController,
      obscurePassword: obscurePassword.value,
      obscureConfirmPassword: obscureConfirmPassword.value,
      isLoading: isLoading,
      onToggleObscure: () => obscurePassword.value = !obscurePassword.value,
      onToggleConfirmObscure: () => obscureConfirmPassword.value = !obscureConfirmPassword.value,
      onSignup: handleSignup,
      cs: cs,
      tt: tt,
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onToggleConfirmObscure,
    required this.onSignup,
    required this.cs,
    required this.tt,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirmObscure;
  final VoidCallback onSignup;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'auth.sign_up'.tr(),
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'auth.sign_up_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: nameController,
                        enabled: !isLoading,
                        label: 'auth.name'.tr(),
                        prefixIcon: const Icon(IconsaxPlusBold.user),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.name_required'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: emailController,
                        enabled: !isLoading,
                        label: 'auth.email'.tr(),
                        prefixIcon: const Icon(IconsaxPlusBold.sms),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.email_required'.tr();
                          }
                          if (!AppUtils.isValidEmail(v!)) {
                            return 'auth.email_invalid'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: passwordController,
                        enabled: !isLoading,
                        label: 'auth.password'.tr(),
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(IconsaxPlusBold.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: onToggleObscure,
                        ),
                         validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.password_required'.tr();
                          }
                          if (v!.length < 6) {
                            return 'auth.password_too_short'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: confirmPasswordController,
                        enabled: !isLoading,
                        label: 'auth.confirm_password'.tr(),
                        obscureText: obscureConfirmPassword,
                        prefixIcon: const Icon(IconsaxPlusBold.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: onToggleConfirmObscure,
                        ),
                         validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.confirm_password_required'.tr();
                          }
                          if (v != passwordController.text) {
                            return 'auth.passwords_do_not_match'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'Sign Up',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : onSignup,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.login);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'auth.already_have_account'.tr(),
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'auth.log_in'.tr(),
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
