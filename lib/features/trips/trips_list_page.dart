import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'join_trip_sheet.dart';
import 'create_trip_sheet.dart';

class TripsListPage extends StatelessWidget {
  const TripsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hasTrips = false; // sementara, nanti diganti data dari BE

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTripActionsSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Logo PNG di kiri atas
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'lib/assets/images/logo_triva.png',
                  height: 44,
                ),
              ),
              const SizedBox(height: 48),

              if (!hasTrips)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon(
                        //   Icons.sentiment_satisfied_alt_outlined,
                        //   size: 40,
                        //   color: AppColors.textSecondary.withOpacity(0.4),
                        // ),
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'lib/assets/images/smile_icon.png',
                            // height: 44,
                          ),
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
                          'Tap  +  to create your first trip.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: SizedBox(), // nanti diganti list trip
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: Start new / Join existing
void _showTripActionsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.3),
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return const _TripActionsSheet();
    },
  );
}

class _TripActionsSheet extends StatelessWidget {
  const _TripActionsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle kecil di atas
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            _TripActionCard(
              emoji: '🚀',
              title: 'Start a new group trip',
              subtitle: 'Create a trip and invite your friends.',
              onTap: () {
                Navigator.pop(context);
                showCreateTripSheet(context);
              },
            ),
            const SizedBox(height: 12),
            _TripActionCard(
              emoji: '🔗',
              title: 'Join an existing group trip',
              subtitle: 'Use an invite link from your friend.',
              onTap: () {
                Navigator.pop(context);
                showJoinTripSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TripActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TripActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
