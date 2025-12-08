import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/theme/app_colors.dart';

class TripCreatedSheet extends StatefulWidget {
  final String tripName;
  final String tripEmoji;
  final List<Map<String, dynamic>> participants;
  final String inviteLink;

  const TripCreatedSheet({
    super.key,
    required this.tripName,
    required this.tripEmoji,
    required this.participants,
    required this.inviteLink,
  });

  @override
  State<TripCreatedSheet> createState() => _TripCreatedSheetState();
}

class _TripCreatedSheetState extends State<TripCreatedSheet> {
  bool _showAllParticipants = false;

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: widget.inviteLink));
    
    // Show custom toast/snackbar
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: MediaQuery.of(context).size.width / 2 - 60,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Text copied',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    
    // Remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _shareLink() async {
    // Check if share is available (not on web)
    if (!ShareHelper.isAvailable) {
      // On web, just copy the link
      _copyLink();
      return;
    }
    
    try {
      await ShareHelper.shareTripInvite(
        tripName: widget.tripName,
        tripEmoji: widget.tripEmoji,
        inviteLink: widget.inviteLink,
      );
    } catch (e) {
      // Fallback to copy if share fails
      debugPrint('Share failed: $e');
      _copyLink();
    }
  }

  List<Map<String, dynamic>> get _displayedParticipants {
    if (_showAllParticipants || widget.participants.length <= 5) {
      return widget.participants;
    }
    return widget.participants.take(5).toList();
  }

  bool get _hasMoreParticipants => widget.participants.length > 5;

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
            // Header dengan close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Title
                  const Text(
                    'Add new trip',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    // Party icon
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 80),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Success message
                    const Text(
                      'Your trip is ready!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'You can start adding friends to join this trip.\nShare the link below or copy it to invite them easily.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Participants section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Participants',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Participants list
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          // Display participants (max 5 or all if expanded)
                          ...List.generate(_displayedParticipants.length, (index) {
                            final participant = _displayedParticipants[index];
                            final isLast = index == _displayedParticipants.length - 1 && 
                                          (!_hasMoreParticipants || _showAllParticipants);
                            
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        participant['name'],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    color: AppColors.border.withValues(alpha: 0.3),
                                    indent: 16,
                                  ),
                              ],
                            );
                          }),
                          
                          // View More button (only if > 5 participants)
                          if (_hasMoreParticipants && !_showAllParticipants) ...[
                            Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: AppColors.border.withValues(alpha: 0.3),
                              indent: 16,
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showAllParticipants = true;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View ${widget.participants.length - 5} more',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.trivaBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppColors.trivaBlue,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Info text
                    Text(
                      'Participant can view, edit, and delete expenses.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Link container with copy and share buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.inviteLink,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Copy button
                          GestureDetector(
                            onTap: _copyLink,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.copy,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Share button
                          GestureDetector(
                            onTap: _shareLink,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.trivaBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Invite Later button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Close all sheets and go back to trips list
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Invite Later',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.trivaBlue,
                          ),
                        ),
                      ),
                    ),
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
void showTripCreatedSheet(
  BuildContext context, {
  required String tripName,
  required String tripEmoji,
  required List<Map<String, dynamic>> participants,
}) {
  // Generate mock invite link
  final inviteLink = 'https://triva.com/xfdwty238ue2';
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withValues(alpha: 0.3),
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => TripCreatedSheet(
      tripName: tripName,
      tripEmoji: tripEmoji,
      participants: participants,
      inviteLink: inviteLink,
    ),
  );
}