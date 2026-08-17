import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/peleka_button.dart';
import '../../core/widgets/peleka_card.dart';
import '../../core/widgets/peleka_text_field.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_view_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _S();
}

class _S extends ConsumerState<ProfileScreen> {
  bool _saving = false;

  Future<void> _edit() async {
    final u = ref.read(authViewModelProvider).user!;
    final n = TextEditingController(text: u.fullName);
    final p = TextEditingController(text: u.phone ?? '');
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(_).viewInsets.bottom),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: AppColors.ink200,
                                  borderRadius: BorderRadius.circular(4)))),
                      const SizedBox(height: 16),
                      const Text('Edit profile',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                      const SizedBox(height: 16),
                      PelekaTextField(
                          label: 'Full name',
                          controller: n,
                          prefixIcon: Icons.person_outline),
                      const SizedBox(height: 12),
                      PelekaTextField(
                          label: 'Phone',
                          controller: p,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 20),
                      PelekaButton(
                          label: 'Save',
                          loading: _saving,
                          onPressed: () async {
                            setState(() => _saving = true);
                            try {
                              final up = await ref
                                  .read(authRepositoryProvider)
                                  .updateProfile(
                                      fullName: n.text.trim(),
                                      phone: p.text.trim().isEmpty
                                          ? null
                                          : p.text.trim());
                              await ref
                                  .read(authViewModelProvider.notifier)
                                  .refreshProfile(up);
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(e
                                            .toString()
                                            .replaceAll('ApiException: ', '')),
                                        backgroundColor: AppColors.error));
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          }),
                    ]))));
  }

  Future<void> _pw() async {
    final c = TextEditingController();
    final x = TextEditingController();
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(_).viewInsets.bottom),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: AppColors.ink200,
                                  borderRadius: BorderRadius.circular(4)))),
                      const SizedBox(height: 16),
                      const Text('Change password',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                      const SizedBox(height: 16),
                      PelekaTextField(
                          label: 'Current password',
                          controller: c,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline),
                      const SizedBox(height: 12),
                      PelekaTextField(
                          label: 'New password',
                          controller: x,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline),
                      const SizedBox(height: 8),
                      const Text('At least 8 chars, letter + number.',
                          style:
                              TextStyle(color: AppColors.ink500, fontSize: 12)),
                      const SizedBox(height: 20),
                      PelekaButton(
                          label: 'Update password',
                          onPressed: () async {
                            try {
                              await ref
                                  .read(authRepositoryProvider)
                                  .changePassword(
                                      current: c.text, next: x.text);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Password updated'),
                                        backgroundColor: AppColors.success));
                              }
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(e
                                            .toString()
                                            .replaceAll('ApiException: ', '')),
                                        backgroundColor: AppColors.error));
                            }
                          }),
                    ]))));
  }

  // ─── DEFINITIVE SIGNOUT FIX ───────────────────────────────────────────
  //
  // Black screen came from navigating with the Profile widget's BuildContext
  // AFTER logout began tearing the ShellRoute down (deactivated context), or
  // from a router that rebuilt itself on auth change.
  //
  // This version:
  //   1) grabs the stable GoRouter from the provider BEFORE logout,
  //   2) flips auth state (logout),
  //   3) navigates with that router object (NOT `context.go`) after the
  //      current frame, so it never touches a dead BuildContext.
  // The router's redirect would also send to /login, so this is belt-and-
  // suspenders: whichever fires first, we always land on a real /login route.
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need to sign in again to book deliveries."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // Grab a stable router handle before we leave this screen. Used only as a
    // fallback if this widget somehow unmounts before we navigate.
    final router = ref.read(routerProvider);

    // 1) Navigate FIRST — context is alive, /login renders immediately.
    if (mounted) {
      context.go('/login');
    } else {
      router.go('/login');
    }

    // 2) Now clear the session. Profile is already off-screen, so there is
    //    nothing left to rebuild into a null-user state.
    await ref.read(authViewModelProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authViewModelProvider).user;
    // During the brief logout transition user is null → show a spinner,
    // never a black screen, until we arrive on /login.
    if (u == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }
    final ini = u.fullName
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0])
        .take(2)
        .join()
        .toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        PelekaCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.navy, AppColors.blue]),
                      borderRadius: BorderRadius.circular(28)),
                  child: Center(
                      child: Text(ini,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)))),
              const SizedBox(height: 16),
              Text(u.fullName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(u.email ?? u.phone ?? '',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.ink500)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit profile'),
                  onPressed: _edit)
            ])),
        const SizedBox(height: 20),
        _lbl('Account'),
        _row(Icons.lock_outline, 'Change password', onTap: _pw),
        _row(Icons.notifications_outlined, 'Notifications',
            onTap: () => context.go('/notifications')),
        _row(Icons.receipt_long_outlined, 'Billing & shipment history',
            onTap: () => context.push('/billing')),
        const SizedBox(height: 20),
        _lbl('Support'),
        _row(Icons.help_outline, 'Help & support', onTap: () {}),
        _row(Icons.verified_user_outlined, 'Privacy policy', onTap: () {}),
        _row(Icons.description_outlined, 'Terms of service', onTap: () {}),
        const SizedBox(height: 20),
        _row(Icons.logout, 'Sign out', color: AppColors.error, onTap: _logout),
        const SizedBox(height: 20),
        const Center(
            child: Text('Peleka · v1.0.0 · Kigali',
                style: TextStyle(color: AppColors.ink400, fontSize: 11))),
      ]),
    );
  }

  Widget _lbl(String s) => Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(s.toUpperCase(),
          style: const TextStyle(
              color: AppColors.ink500,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)));
  Widget _row(IconData i, String l, {VoidCallback? onTap, Color? color}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PelekaCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: onTap,
              child: Row(children: [
                Icon(i, size: 20, color: color ?? AppColors.navy),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(l,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color ?? AppColors.navy))),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.ink400)
              ])));
}
