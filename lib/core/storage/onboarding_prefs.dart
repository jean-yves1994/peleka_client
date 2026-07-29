import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefs {
  static const _k = 'peleka.onboarding_seen';
  Future<bool> seen() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_k) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSeen() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_k, true);
    } catch (_) {}
  }
}

final onboardingPrefsProvider =
    Provider<OnboardingPrefs>((ref) => OnboardingPrefs());
