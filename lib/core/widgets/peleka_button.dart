import 'package:flutter/material.dart';

class PelekaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool outlined;
  final bool fullWidth;
  final Color? color;
  const PelekaButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.loading = false,
      this.icon,
      this.outlined = false,
      this.fullWidth = true,
      this.color});
  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8)
            ],
            Text(label)
          ]);
    final btn = outlined
        ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
        : ElevatedButton(
            style: color != null
                ? ElevatedButton.styleFrom(backgroundColor: color)
                : null,
            onPressed: loading ? null : onPressed,
            child: child);
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
