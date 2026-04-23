import 'dart:async';

import 'package:libaas/features/auth/view_model/auth_provider.dart';
import 'package:libaas/features/auth/view_model/auth_state.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() { _secondsRemaining = 60; _canResend = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _onVerifyOtp(String otp) {
    if (otp.length == 6) {
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).verifyOtp(
            otp: otp,
            phoneNumber: widget.phoneNumber,
          );
    }
  }

  String get _maskedPhone {
    final p = widget.phoneNumber;
    if (p.length >= 7) {
      return '${p.substring(0, 6)} *** ${p.substring(p.length - 4)}';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthNewUser) {
        context.go('/setup');
      } else if (next is AuthExistingUser) {
        context.go('/home/orders');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final isLoading = ref.watch(authProvider) is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.dark, size: 20),
          onPressed: () {
            ref.read(authProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Verify your\nphone number',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, color: AppColors.gray),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to '),
                    TextSpan(
                      text: _maskedPhone,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
              Center(child: _buildOtpInput()),
              const SizedBox(height: 36),
              _buildVerifyButton(isLoading),
              const SizedBox(height: 28),
              Center(child: _buildResendRow()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    final defaultTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
    );

    return Pinput(
      controller: _otpController,
      length: 6,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navy, width: 2),
        ),
      ),
      submittedPinTheme: defaultTheme.copyWith(
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navy.withValues(alpha: 0.3)),
        ),
      ),
      keyboardType: TextInputType.number,
      autofocus: true,
      onCompleted: _onVerifyOtp,
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => _onVerifyOtp(_otpController.text.trim()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: AppColors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Verify OTP',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
      ),
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        _canResend
            ? GestureDetector(
                onTap: () {
                  _otpController.clear();
                  _startCountdown();
                  ref.read(authProvider.notifier).resendOtp(widget.phoneNumber);
                },
                child: const Text(
                  'Resend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              )
            : Text(
                'Resend in ${_secondsRemaining}s',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
      ],
    );
  }
}
