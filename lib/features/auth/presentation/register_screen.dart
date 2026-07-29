import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_text_field.dart';
import 'auth_view_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _S();
}

class _S extends ConsumerState<RegisterScreen> {
  final _f = GlobalKey<FormState>();
  final _n = TextEditingController();
  final _e = TextEditingController();
  final _p = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _n.dispose();
    _e.dispose();
    _p.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final ok = await ref.read(authViewModelProvider.notifier).register(
        fullName: _n.text.trim(),
        email: _e.text.trim().isEmpty ? null : _e.text.trim(),
        phone: _p.text.trim().isEmpty ? null : _p.text.trim(),
        password: _pw.text);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(authViewModelProvider);
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop())),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                    key: _f,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create your account',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy)),
                          const SizedBox(height: 6),
                          const Text(
                              'Provide email OR phone (or both). Password required.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.ink500)),
                          const SizedBox(height: 24),
                          PelekaTextField(
                              label: 'Full name',
                              hint: 'Aline Uwimana',
                              controller: _n,
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Required'
                                      : null),
                          const SizedBox(height: 14),
                          PelekaTextField(
                              label: 'Email',
                              hint: 'you@example.rw',
                              controller: _e,
                              prefixIcon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          PelekaTextField(
                              label: 'Phone',
                              hint: '+2507XX XXX XXX',
                              controller: _p,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                final e = _e.text.trim().isNotEmpty;
                                final p = (v ?? '').trim().isNotEmpty;
                                return (!e && !p)
                                    ? 'Email or phone required'
                                    : null;
                              }),
                          const SizedBox(height: 14),
                          PelekaTextField(
                              label: 'Password',
                              hint: 'At least 8 chars, letter + number',
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
                              validator: (v) {
                                if (v == null || v.length < 8)
                                  return 'At least 8 characters';
                                if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
                                    !RegExp(r'[0-9]').hasMatch(v))
                                  return 'Must include a letter and a number';
                                return null;
                              }),
                          if (a.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(a.error!,
                                    style: const TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontSize: 13)))
                          ],
                          const SizedBox(height: 24),
                          PelekaButton(
                              label: 'Create account',
                              loading: a.loading,
                              onPressed: _submit),
                        ])))));
  }
}
