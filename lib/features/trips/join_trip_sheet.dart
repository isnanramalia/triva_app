import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// Import ini untuk digunakan di trips_list_page.dart
// import 'join_trip_sheet.dart';

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
                      child: Icon(
                        Icons.link_rounded,
                        size: 40,
                        color: AppColors.textSecondary.withOpacity(0.6),
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