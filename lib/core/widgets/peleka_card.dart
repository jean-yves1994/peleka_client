import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PelekaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const PelekaCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.color,
      this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.ink100)),
              padding: padding,
              child: child)));
}
