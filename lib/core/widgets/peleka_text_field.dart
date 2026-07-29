import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PelekaTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  const PelekaTextField(
      {super.key,
      required this.label,
      this.hint,
      this.controller,
      this.keyboardType,
      this.obscureText = false,
      this.prefixIcon,
      this.suffix,
      this.maxLines = 1,
      this.validator,
      this.onChanged,
      this.enabled = true});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink700))),
        TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            validator: validator,
            onChanged: onChanged,
            enabled: enabled,
            decoration: InputDecoration(
                hintText: hint,
                prefixIcon: prefixIcon == null
                    ? null
                    : Icon(prefixIcon, size: 18, color: AppColors.ink400),
                suffixIcon: suffix)),
      ]);
}
