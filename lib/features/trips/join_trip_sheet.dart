import 'package:flutter/material.dart';
import 'package:triva_app/features/trip_detail/trip_detail_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';

class JoinTripSheet extends StatefulWidget {
  const JoinTripSheet({super.key});

  @override
  State<JoinTripSheet> createState() => _JoinTripSheetState();
}

class _JoinTripSheetState extends State<JoinTripSheet> {
  final _linkController = TextEditingController();
  bool _isLoading = false;

  // Di dalam _JoinTripSheetState

  String _extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('/')) {
      // Akan mengambil bagian terakhir setelah slash (bekerja untuk /trips/ atau /join/)
      return trimmed.split('/').last;
    }
    return trimmed;
  }

  Future<void> _handleJoin() async {
    final input = _linkController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final token = _extractToken(input);
      final tripData = await TripService().joinTrip(token);

      if (mounted && tripData != null) {
        Navigator.pop(context, tripData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = e.toString().replaceAll('Exception: ', '');

        Navigator.pop(context, {'error': errorMessage});
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REVISI: Menggunakan 0.85 (85%) agar logo di background terlihat
    final double sheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 32),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.trivaBlue,
                          fontSize: 16,
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🔗', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Join a trip',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste the link you received below to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.trivaBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
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

/// Helper function
Future<dynamic> showJoinTripSheet(BuildContext context) {
  return showModalBottomSheet<dynamic>(
    // Tambahkan return
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (ctx) => const JoinTripSheet(),
  );
}
