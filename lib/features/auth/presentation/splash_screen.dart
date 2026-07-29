import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

/// Pure loading screen. It does NOT navigate — the router's `redirect`
/// moves the user to /onboarding, /login, or /home the moment auth
/// bootstrap finishes. This removes the dueling-navigation bug that
/// caused the infinite spinner.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1),
                children: [
                  TextSpan(
                      text: 'PELEKA', style: TextStyle(color: Colors.white)),
                  TextSpan(
                      text: '.', style: TextStyle(color: AppColors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Kigali courier delivery',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 40),
            const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.orange)),
          ],
        ),
      ),
    );
  }
}
