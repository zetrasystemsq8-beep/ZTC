import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import '../providers/auth_provider.dart';
import 'package:ztc_bank/src/routing/app_routes.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleLogin() async {
      if (!(formKey.currentState?.validate() ?? false)) return;

      ref.read(authProvider.notifier).signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.xl.h),
              Text(
                'auth.log_in'.tr(),
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                'auth.log_in_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.xxxl.h),
              Form(
                key: formKey,
                child: Column(
                  children: [
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
                      obscureText: obscurePassword.value,
                      prefixIcon: const Icon(IconsaxPlusBold.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword.value ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => obscurePassword.value = !obscurePassword.value,
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
                    SizedBox(height: AppSpacing.sm.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          'auth.forgot_password'.tr(),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    AppButton(
                      label: 'Sign In',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : handleLogin,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              InkWell(
                onTap: () => context.push(AppRoutes.signup),
                child: RichText(
                  text: TextSpan(
                    text: 'auth.dont_have_account'.tr(),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: ' auth.sign_up'.tr(),
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
