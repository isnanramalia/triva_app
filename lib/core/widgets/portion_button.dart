import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PortionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const PortionButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }
}
