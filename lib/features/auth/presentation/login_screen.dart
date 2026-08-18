import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_text_field.dart';
import 'auth_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _S();
}

class _S extends ConsumerState<LoginScreen> {
  final _f = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  int _tab = 0;
  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final ok = await ref.read(authViewModelProvider.notifier).login(
        email: _tab == 0 ? _id.text.trim() : null,
        phone: _tab == 1 ? _id.text.trim() : null,
        password: _pw.text);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(authViewModelProvider);
    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                    key: _f,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          RichText(
                              text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5),
                                  children: [
                                TextSpan(
                                    text: 'PELEKA',
                                    style: TextStyle(color: AppColors.navy)),
                                TextSpan(
                                    text: '.',
                                    style: TextStyle(color: AppColors.orange))
                              ])),
                          const SizedBox(height: 20),
                          const Text('Welcome back 👋',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy)),
                          const SizedBox(height: 6),
                          const Text('Sign in to book fast Kigali deliveries.',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.ink500)),
                          const SizedBox(height: 28),
                          Container(
                              decoration: BoxDecoration(
                                  color: AppColors.ink100,
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.all(4),
                              child: Row(children: [
                                _tb('Email', 0),
                                _tb('Phone', 1)
                              ])),
                          const SizedBox(height: 20),
                          PelekaTextField(
                              label: _tab == 0 ? 'Email' : 'Phone number',
                              hint: _tab == 0
                                  ? 'you@example.rw'
                                  : '+2507XX XXX XXX',
                              controller: _id,
                              prefixIcon: _tab == 0
                                  ? Icons.mail_outline
                                  : Icons.phone_outlined,
                              keyboardType: _tab == 0
                                  ? TextInputType.emailAddress
                                  : TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null),
                          const SizedBox(height: 16),
                          PelekaTextField(
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _pw,
                              obscureText: _obscure,
                              prefixIcon: Icons.lock_outline,
                              suffix: IconButton(
                                  icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: AppColors.ink500),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure)),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null),
                          const SizedBox(height: 12),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  child: const Text('Forgot password?'))),
                          if (a.error != null) ...[
                            const SizedBox(height: 8),
                            _err(a.error!)
                          ],
                          const SizedBox(height: 20),
                          PelekaButton(
                              label: 'Sign in',
                              loading: a.loading,
                              onPressed: _submit),
                          const SizedBox(height: 28),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('New to Peleka? ',
                                    style: TextStyle(color: AppColors.ink500)),
                                GestureDetector(
                                    onTap: () => context.push('/register'),
                                    child: const Text('Create account',
                                        style: TextStyle(
                                            color: AppColors.orange,
                                            fontWeight: FontWeight.w700)))
                              ]),
                        ])))));
  }

  Widget _tb(String l, int i) {
    final s = _tab == i;
    return Expanded(
        child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: s ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: s
                        ? [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1))
                          ]
                        : null),
                child: Text(l,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: s ? AppColors.navy : AppColors.ink500)))));
  }

  Widget _err(String m) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12)),
      child: Text(m,
          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)));
}
