import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.icon,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.monospace = false,
  });

  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscureText;
  final int minLines;
  final int maxLines;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkDim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            minLines: minLines,
            maxLines: obscureText ? 1 : maxLines,
            style: TextStyle(
              fontFamily: monospace ? 'monospace' : null,
              fontSize: monospace ? 13 : null,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, color: AppColors.inkSub, size: 18),
              filled: true,
              fillColor: AppColors.bgPure.withValues(alpha: 0.7),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: _border(const Color(0x140A0A0A)),
              enabledBorder: _border(const Color(0x140A0A0A)),
              focusedBorder: _border(AppColors.primaryBorder),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color),
    );
  }
}
