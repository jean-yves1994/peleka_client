import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});
  int _i(String l) {
    if (l.startsWith('/shipments')) return 1;
    if (l.startsWith('/notifications')) return 2;
    if (l.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _i(GoRouterState.of(context).matchedLocation);
    return Scaffold(
        body: child,
        bottomNavigationBar: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                    top: BorderSide(color: AppColors.ink100, width: 1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ]),
            child: SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _N(
                              icon: Icons.home_outlined,
                              label: 'Home',
                              sel: idx == 0,
                              onTap: () => context.go('/home')),
                          _N(
                              icon: Icons.inventory_2_outlined,
                              label: 'Shipments',
                              sel: idx == 1,
                              onTap: () => context.go('/shipments')),
                          _N(
                              icon: Icons.notifications_outlined,
                              label: 'Alerts',
                              sel: idx == 2,
                              onTap: () => context.go('/notifications')),
                          _N(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              sel: idx == 3,
                              onTap: () => context.go('/profile')),
                        ])))));
  }
}

class _N extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool sel;
  final VoidCallback onTap;
  const _N(
      {required this.icon,
      required this.label,
      required this.sel,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: sel ? AppColors.orangeLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(999)),
                child: Icon(icon,
                    size: 20,
                    color: sel ? AppColors.orange : AppColors.ink500)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.orange : AppColors.ink500))
          ])));
}
