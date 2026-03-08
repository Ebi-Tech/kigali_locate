import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to check if email was verified
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final verified = await ref
        .read(authNotifierProvider.notifier)
        .reloadAndCheckVerification();
    if (verified && mounted) {
      _timer?.cancel();
      ref.invalidate(authStateProvider);
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });

    await ref.read(authNotifierProvider.notifier).sendVerificationEmail();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    }

    // Cooldown timer
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        t.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.accent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                AppStrings.verifyEmailTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.verifyEmailBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 12),
                Text(
                  user!.email!,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _checkVerification,
                child: const Text(AppStrings.checkVerification),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _canResend ? _resendEmail : null,
                child: Text(
                  _canResend
                      ? AppStrings.resendEmail
                      : 'Resend in ${_resendCooldown}s',
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
