import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final zetramailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);
    final zetramailFocus = useFocusNode();
    final passwordFocus = useFocusNode();

    final entrance = useAnimationController(duration: const Duration(milliseconds: 900));
    useEffect(() {
      entrance.forward();
      return null;
    }, []);
    final fade = CurvedAnimation(parent: entrance, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: entrance, curve: Curves.easeOutCubic));

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenData((s) {
        if (s.stage == AuthStage.awaitingOtp) {
          context.push('/verify-otp');
        }
      });
    });

    final errorMessage =
        authState.hasError ? authState.error.toString().replaceFirst('Exception: ', '') : null;

    Future<void> submit() async {
      FocusScope.of(context).unfocus();
      if (!formKey.currentState!.validate()) return;
      await ref.read(authProvider.notifier).login(
            zetramail: zetramailController.text.trim(),
            password: passwordController.text.trim(),
          );
    }

    const deepNavy = Color(0xFF0B1220);
    const emerald = Color(0xFF10B77F);
    const emeraldSoft = Color(0xFF17D9A3);

    return Scaffold(
      backgroundColor: deepNavy,
      body: Stack(
        children: [
          // Soft ambient gradient blobs for depth — not flat, not stock.
          Positioned(
            top: -120.h,
            right: -80.w,
            child: _GlowBlob(color: emerald.withOpacity(0.35), size: 280.w),
          ),
          Positioned(
            bottom: -140.h,
            left: -100.w,
            child: _GlowBlob(color: emeraldSoft.withOpacity(0.22), size: 320.w),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 12.h),
                            Center(
                              child: Container(
                                width: 88.w,
                                height: 88.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [emerald, emeraldSoft],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(26.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: emerald.withOpacity(0.45),
                                      blurRadius: 30,
                                      spreadRadius: -4,
                                      offset: Offset(0, 14.h),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.account_balance_wallet_rounded, size: 44.sp, color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 28.h),
                            Text(
                              'Welcome back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Sign in with your ZetraMail address',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.6)),
                            ),
                            SizedBox(height: 36.h),

                            // Glass card holding the form.
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24.r),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  padding: EdgeInsets.all(20.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(24.r),
                                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                                  ),
                                  child: Form(
                                    key: formKey,
                                    child: Column(
                                      children: [
                                        _FrostedField(
                                          controller: zetramailController,
                                          focusNode: zetramailFocus,
                                          label: 'ZetraMail address',
                                          hint: 'you@zetramail.ng',
                                          icon: Icons.email_outlined,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) => passwordFocus.requestFocus(),
                                          validator: (v) {
                                            final email = v?.trim() ?? '';
                                            if (email.isEmpty) return 'Please enter your ZetraMail address';
                                            final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                                            if (!emailRegex.hasMatch(email)) return 'Please enter a valid email';
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 14.h),
                                        _FrostedField(
                                          controller: passwordController,
                                          focusNode: passwordFocus,
                                          label: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: obscurePassword.value,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => submit(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obscurePassword.value
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color: Colors.white.withOpacity(0.5),
                                              size: 20.sp,
                                            ),
                                            onPressed: () => obscurePassword.value = !obscurePassword.value,
                                          ),
                                          validator: (v) {
                                            final password = v ?? '';
                                            if (password.isEmpty) return 'Please enter your password';
                                            if (password.length < 8) return 'Password must be at least 8 characters';
                                            return null;
                                          },
                                        ),
                                        AnimatedSize(
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                          child: errorMessage == null
                                              ? const SizedBox(width: double.infinity)
                                              : Padding(
                                                  padding: EdgeInsets.only(top: 14.h),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEF4444).withOpacity(0.14),
                                                      borderRadius: BorderRadius.circular(12.r),
                                                      border: Border.all(
                                                        color: const Color(0xFFEF4444).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.error_outline_rounded,
                                                            color: const Color(0xFFFF6B6B), size: 18.sp),
                                                        SizedBox(width: 8.w),
                                                        Expanded(
                                                          child: Text(
                                                            errorMessage,
                                                            style: TextStyle(
                                                              color: const Color(0xFFFF9B9B),
                                                              fontSize: 12.5.sp,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined, size: 15.sp, color: Colors.white.withOpacity(0.4)),
                                SizedBox(width: 6.w),
                                Text(
                                  'Secured by your Zetra ID',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 28.h),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              colors: isLoading ? [Colors.grey.shade700, Colors.grey.shade700] : [emerald, emeraldSoft],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: isLoading
                                ? []
                                : [
                                    BoxShadow(
                                      color: emerald.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: Offset(0, 8.h),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: isLoading ? null : submit,
                              child: Center(
                                child: isLoading
                                    ? SizedBox(
                                        width: 24.w,
                                        height: 24.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Log In',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Icon(Icons.arrow_forward_rounded, size: 18.sp, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft blurred color blob used for ambient background depth.
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// A text field styled for the dark glass card — filled, borderless,
/// with a focus-aware accent border drawn via the decoration.
class _FrostedField extends HookWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _FrostedField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.hint,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = useState(false);
    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    const emeraldSoft = Color(0xFF17D9A3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isFocused.value ? emeraldSoft.withOpacity(0.8) : Colors.white.withOpacity(0.1),
          width: isFocused.value ? 1.4 : 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: TextStyle(color: Colors.white, fontSize: 15.sp),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13.sp),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.45), size: 20.sp),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          errorStyle: const TextStyle(color: Color(0xFFFF9B9B)),
        ),
      ),
    );
  }
}
