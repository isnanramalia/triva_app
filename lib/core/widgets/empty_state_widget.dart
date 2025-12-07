import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageAsset;
  final double imageSize;
  final double bottomPadding;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.imageAsset = 'lib/assets/images/smile_icon.png',
    this.imageSize = 60.0,
    this.bottomPadding = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gambar
            Image.asset(
              imageAsset!,
              height: imageSize,
              fit: BoxFit.contain,
              errorBuilder: (context, object, stackTrace) =>
                  Icon(Icons.sentiment_satisfied, size: imageSize, color: Colors.grey.shade400),
            ),

            const SizedBox(height: 24),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}