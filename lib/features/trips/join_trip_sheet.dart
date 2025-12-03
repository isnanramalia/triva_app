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

class JoinTripSheet extends StatefulWidget {
  const JoinTripSheet({super.key});

  @override
  State<JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends State<JoinTripSheet> {
  final _linkController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header dengan handle dan Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Cancel button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.trivaBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🔗',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Join a trip',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'Paste the link you received below to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Input field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _linkController,
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste Link Here',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.3),
                            fontSize: 17,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Join button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Handle join trip
                          if (_linkController.text.isNotEmpty) {
                            // Process join
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.trivaBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function untuk show join trip sheet
void showJoinTripSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.3),
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const JoinTripSheet(),
  );
}