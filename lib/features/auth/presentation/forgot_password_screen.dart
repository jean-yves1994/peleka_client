import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_text_field.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _identifier.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final value = _identifier.text.trim();
      final method = await ref.read(authRepositoryProvider).requestPasswordReset(value);
      if (!mounted) return;
      if (method == 'phone') {
        context.push('/forgot-password/phone', extra: value);
      } else {
        context.push('/forgot-password/email');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll(RegExp(r'^ApiException\([^)]*\):\s*'), ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Forgot password?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 6),
          const Text('Enter the email or phone number linked to your Peleka account.', style: TextStyle(fontSize: 13, color: AppColors.ink500)),
          const SizedBox(height: 28),
          PelekaTextField(
            label: 'Email or phone number',
            hint: 'you@example.rw or +2507XX XXX XXX',
            controller: _identifier,
            prefixIcon: Icons.person_search_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your email or phone number' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: _error!),
          ],
          const SizedBox(height: 24),
          PelekaButton(label: 'Continue', loading: _loading, onPressed: _submit),
          const SizedBox(height: 18),
          const Text('For your security, we never reveal whether an account exists for a submitted contact.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.ink500)),
        ])),
      )),
    );
  }
}

class EmailResetSentScreen extends StatelessWidget {
  const EmailResetSentScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login'))),
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      const Icon(Icons.mark_email_read_outlined, size: 58, color: AppColors.orange),
      const SizedBox(height: 24),
      const Text('Check your email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
      const SizedBox(height: 8),
      const Text('If a Peleka account exists for that email, we sent a password reset link. The link expires in 60 minutes.', style: TextStyle(fontSize: 14, color: AppColors.ink500)),
      const Spacer(),
      PelekaButton(label: 'Back to sign in', onPressed: () => context.go('/login')),
    ]))),
  );
}

class PhoneResetScreen extends ConsumerStatefulWidget {
  final String phone;
  const PhoneResetScreen({super.key, required this.phone});
  @override
  ConsumerState<PhoneResetScreen> createState() => _PhoneResetScreenState();
}

class _PhoneResetScreenState extends ConsumerState<PhoneResetScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;
  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final token = await ref.read(authRepositoryProvider).verifyPasswordResetPhone(phone: widget.phone, code: _code.text.trim());
      if (mounted) context.push('/reset-password', extra: token);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll(RegExp(r'^ApiException\([^)]*\):\s*'), ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Enter verification code', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
      const SizedBox(height: 8),
      Text('We sent a 6-digit code to ${_maskPhone(widget.phone)}. It expires in 5 minutes.', style: const TextStyle(fontSize: 13, color: AppColors.ink500)),
      const SizedBox(height: 28),
      PelekaTextField(label: 'Verification code', hint: '000000', controller: _code, prefixIcon: Icons.password_outlined, keyboardType: TextInputType.number, validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'Enter the 6-digit code'),
      if (_error != null) ...[const SizedBox(height: 12), _ErrorBox(message: _error!)],
      const SizedBox(height: 24),
      PelekaButton(label: 'Verify code', loading: _loading, onPressed: _verify),
    ]))),
  );

  String _maskPhone(String p) {
    final x = p.replaceAll(RegExp(r'\s+'), '');
    if (x.length < 6) return x;
    return '${x.substring(0, 4)} •••• ${x.substring(x.length - 3)}';
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _cpw = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  @override
  void dispose() { _pw.dispose(); _cpw.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).resetPassword(token: widget.token, password: _pw.text);
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll(RegExp(r'^ApiException\([^)]*\):\s*'), ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login'))),
    body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Create a new password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
      const SizedBox(height: 8),
      const Text('Choose a new password for your Peleka account.', style: TextStyle(fontSize: 13, color: AppColors.ink500)),
      const SizedBox(height: 28),
      PelekaTextField(label: 'New password', hint: 'At least 8 chars, letter + number', controller: _pw, obscureText: _obscure, prefixIcon: Icons.lock_outline, suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.ink500), onPressed: () => setState(() => _obscure = !_obscure)), validator: (v) { if ((v ?? '').length < 8) return 'At least 8 characters'; if (!RegExp(r'[A-Za-z]').hasMatch(v!) || !RegExp(r'[0-9]').hasMatch(v)) return 'Must include a letter and a number'; return null; }),
      const SizedBox(height: 14),
      PelekaTextField(label: 'Confirm password', hint: 'Re-enter your password', controller: _cpw, obscureText: _obscure, prefixIcon: Icons.lock_reset_outlined, validator: (v) => (v ?? '') == _pw.text ? null : 'Passwords do not match'),
      if (_error != null) ...[const SizedBox(height: 12), _ErrorBox(message: _error!)],
      const SizedBox(height: 24),
      PelekaButton(label: 'Reset password', loading: _loading, onPressed: _submit),
    ]))),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)), child: Text(message, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)));
}
