import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_text_field.dart';
import '../data/auth_repository.dart';
import 'auth_view_model.dart';

/// Phone login — FIREBASE ONLY.
///
/// Flow:
///   Step 0  enter phone → FirebaseAuth.verifyPhoneNumber (sends SMS)
///   Step 1  enter 6-digit code → signInWithCredential → getIdToken()
///           → POST /api/auth/firebase-phone → Peleka JWTs → /home
///
/// On a real Android device with Google Play Services the code is often
/// auto-detected (verificationCompleted fires and we skip straight to
/// token exchange). On iOS / other devices the user types the code.
class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();

  int _step = 0;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  String? _verificationId;
  int? _resendToken;
  int _cooldown = 0;
  Timer? _timer;
  bool _needsName = false;

  @override
  void initState() {
    super.initState();
    if (widget.phone.isNotEmpty) _phone.text = widget.phone;
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool _validPhone(String p) => RegExp(r'^\+?[0-9\s\-()]{6,}$').hasMatch(p.trim());

  // ─── Step 1: send SMS via Firebase ───
  Future<void> _send() async {
    final phone = _phone.text.trim();
    if (!_validPhone(phone)) {
      setState(() => _error = 'Enter a valid phone number, e.g. +250788111222');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        // Android auto-retrieval: sign in immediately, no manual code entry.
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _exchange(credential);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _step = 1;
            _sending = false;
            _cooldown = 60;
          });
          _startCooldown();
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() { _sending = false; _error = _pretty(e); });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) setState(() { _sending = false; _error = e.toString(); });
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown == 0) t.cancel();
    });
  }

  // ─── Step 2: verify typed code ───
  Future<void> _verify() async {
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_verificationId == null) {
      setState(() => _error = 'Send the code first');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _code.text.trim(),
      );
      await _exchange(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _verifying = false; _error = _pretty(e); });
    } catch (e) {
      if (mounted) setState(() { _verifying = false; _error = e.toString(); });
    }
  }

  // Sign in with Firebase → get ID token → swap for Peleka JWTs.
  Future<void> _exchange(PhoneAuthCredential credential) async {
    setState(() => _verifying = true);
    try {
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCred.user?.getIdToken();
      if (idToken == null) throw Exception('No Firebase id_token');
      try {
        final user = await ref.read(authRepositoryProvider).exchangeFirebaseIdToken(
              idToken: idToken,
              fullName: _needsName ? _name.text.trim() : null,
            );
        await ref.read(authViewModelProvider.notifier).refreshProfile(user);
        if (mounted) context.go('/home');
      } catch (e) {
        final msg = e.toString();
        if (msg.toLowerCase().contains('full_name')) {
          setState(() {
            _needsName = true;
            _verifying = false;
            _error = 'New here? Please enter your name to finish.';
          });
        } else {
          setState(() { _verifying = false; _error = msg.replaceAll('ApiException: ', ''); });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _verifying = false; _error = e.toString(); });
    }
  }

  String _pretty(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number': return "That doesn't look like a valid phone number.";
      case 'invalid-verification-code': return 'Incorrect code. Please try again.';
      case 'session-expired': return 'Code expired. Send a new one.';
      case 'too-many-requests': return 'Too many attempts. Try again in a few minutes.';
      case 'quota-exceeded': return 'Daily SMS quota reached. Please try again tomorrow.';
      case 'missing-client-identifier':
        return 'App not verified with Firebase. Add your SHA-1 in Firebase Console and re-download google-services.json.';
      default: return e.message ?? e.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _step == 1
              ? setState(() { _step = 0; _code.clear(); _error = null; _needsName = false; })
              : context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: _step == 0 ? _stepPhone() : _stepCode(),
        ),
      ),
    );
  }

  Widget _stepPhone() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.smartphone, color: AppColors.blue, size: 28),
        ),
        const SizedBox(height: 24),
        const Text('Sign in with phone',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text("We'll send a 6-digit code by SMS to verify your number.",
            style: TextStyle(fontSize: 13, color: AppColors.ink500)),
        const SizedBox(height: 24),
        PelekaTextField(
          label: 'Phone number',
          hint: '+2507XX XXX XXX',
          controller: _phone,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        const Text('Include the country code, e.g. +250788111222',
            style: TextStyle(fontSize: 11, color: AppColors.ink500)),
        if (_error != null) ...[const SizedBox(height: 12), _banner(_error!)],
        const SizedBox(height: 24),
        PelekaButton(label: 'Send code', loading: _sending, onPressed: _send),
      ]);

  Widget _stepCode() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('Enter code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 6),
        Text('Sent to ${_phone.text.trim()}',
            style: const TextStyle(fontSize: 13, color: AppColors.ink500)),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(letterSpacing: 12, color: AppColors.ink400),
          ),
          onChanged: (v) { if (v.length == 6) _verify(); },
        ),
        if (_needsName) ...[
          const SizedBox(height: 8),
          const Text('New account — please tell us your name.',
              style: TextStyle(color: AppColors.ink500, fontSize: 12)),
          const SizedBox(height: 12),
          PelekaTextField(label: 'Full name', hint: 'Aline Uwimana', controller: _name, prefixIcon: Icons.person_outline),
        ],
        if (_error != null) ...[const SizedBox(height: 12), _banner(_error!)],
        const SizedBox(height: 24),
        PelekaButton(label: 'Verify & continue', loading: _verifying, onPressed: _verify),
        const SizedBox(height: 16),
        Center(
          child: _cooldown > 0
              ? Text('Resend in ${_cooldown}s', style: const TextStyle(color: AppColors.ink500))
              : TextButton(
                  onPressed: _sending ? null : () { setState(() => _step = 0); _send(); },
                  child: const Text('Resend code'),
                ),
        ),
      ]);

  Widget _banner(String m) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Color(0xFF991B1B), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(m, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13))),
        ]),
      );
}
