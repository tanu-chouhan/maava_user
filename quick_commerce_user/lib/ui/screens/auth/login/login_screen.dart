import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../navigation/route_paths.dart';
import '../../../common/widgets/buttons/primary_button.dart';
import '../../../common/widgets/inputs/app_text_field.dart';
import '../../splash/splash_screen.dart';
import 'login_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final sent = await ref.read(loginProvider.notifier).requestOtp();
    if (!sent || !mounted) return;

    final state = ref.read(loginProvider);
    context.push(
      RoutePaths.otp,
      extra: (phone: state.phone, debugOtp: state.debugOtp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const SuvioMark(size: 62, onPrimary: false),
              const SizedBox(height: AppSpacing.xxl),
              Text(AppStrings.loginTitle, style: context.text.displaySmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.loginSubtitle,
                style: context.text.bodyLarge!
                    .copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                controller: _controller,
                hint: '00000 00000',
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                errorText: state.validationError ?? state.failure?.message,
                onChanged: ref.read(loginProvider.notifier).setPhone,
                onSubmitted: (_) => state.canSubmit ? _submit() : null,
                prefix: const _CountryCode(),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: AppStrings.continueLabel,
                isLoading: state.isSubmitting,
                onPressed: state.canSubmit ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'By continuing you agree to our Terms of Service and Privacy '
                'Policy.',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed +91: the backend's OTP flow is India-only today.
class _CountryCode extends StatelessWidget {
  const _CountryCode();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🇮🇳', style: context.text.bodyLarge),
          const SizedBox(width: AppSpacing.sm),
          Text('+91', style: context.text.titleMedium),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 1,
            height: 22,
            decoration: BoxDecoration(
              color: context.semantic.border,
              borderRadius: AppRadii.rSm,
            ),
          ),
        ],
      ),
    );
  }
}
