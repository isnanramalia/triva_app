import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TripsListPage extends StatelessWidget {
  const TripsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // untuk sementara anggap belum ada trip
    final hasTrips = false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate ke Create Trip flow
        },
        backgroundColor: AppColors.trivaBlue,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/images/logo_triva.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 48),

              if (!hasTrips) ...[
                // Empty state (tengah layar)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                          size: 40,
                          color: AppColors.textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trips yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to create your first trip.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Nanti di sini list trip kalo sudah ada data
                Expanded(
                  child: ListView.builder(
                    itemCount: 0,
                    itemBuilder: (context, index) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
