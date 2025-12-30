import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AiAddTab extends StatelessWidget {
  const AiAddTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // === UI TETAP ===
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.trivaBlue.withOpacity(0.5),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'AI Features Coming Soon! 🚀',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.trivaBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
