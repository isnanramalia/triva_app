import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart'; // Import Service

class TripCreatedSheet extends StatefulWidget {
  final int tripId; // ✅ Ganti inviteLink dengan tripId
  final String tripName;
  final String tripEmoji;
  final List<Map<String, dynamic>> participants;

  const TripCreatedSheet({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.tripEmoji,
    required this.participants,
  });

  @override
  State<TripCreatedSheet> createState() => _TripCreatedSheetState();
}

class _TripCreatedSheetState extends State<TripCreatedSheet> {
  bool _showAllParticipants = false;
  String _inviteLink = 'Generating link...'; // Default loading text
  bool _isLinkLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchInviteLink(); // ✅ Ambil link otomatis saat dibuka
  }

  Future<void> _fetchInviteLink() async {
    final link = await TripService().getShareLink(widget.tripId);
    if (mounted) {
      setState(() {
        _inviteLink = link ?? 'Failed to get link';
        _isLinkLoaded = link != null;
      });
    }
  }

  void _copyLink() {
    if (!_isLinkLoaded) return; // Cegah copy kalau belum load
    Clipboard.setData(ClipboardData(text: _inviteLink));

    // ... (Kode Toast/Snackbar copy tetap sama) ...
    // Copy paste logic toast yang lama di sini
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
                Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Text copied',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void _shareLink() async {
    if (!_isLinkLoaded) return;
    if (!ShareHelper.isAvailable) {
      _copyLink();
      return;
    }
    try {
      await ShareHelper.shareTripInvite(
        tripName: widget.tripName,
        tripEmoji: widget.tripEmoji,
        inviteLink: _inviteLink,
      );
    } catch (e) {
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
      // ✅ FIX UI 1: Kurangi tinggi (sebelumnya 0.92)
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Text(
                    'Trip Created', // Ubah text dikit biar pas
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 24),
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
                      'You can start adding friends to join this trip.\nShare the link below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Participants List (Tetap sama logicnya)
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border,
                        ), // Tambah border tipis biar rapi
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_displayedParticipants.length, (
                            index,
                          ) {
                            final p = _displayedParticipants[index];
                            final isLast =
                                index == _displayedParticipants.length - 1 &&
                                (!_hasMoreParticipants || _showAllParticipants);
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Text(
                                        p['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    indent: 16,
                                  ),
                              ],
                            );
                          }),
                          if (_hasMoreParticipants &&
                              !_showAllParticipants) ...[
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 16,
                            ),
                            InkWell(
                              onTap: () =>
                                  setState(() => _showAllParticipants = true),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Center(
                                  child: Text(
                                    'View ${widget.participants.length - 5} more',
                                    style: const TextStyle(
                                      color: AppColors.trivaBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Link Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _isLinkLoaded
                                ? Text(
                                    _inviteLink,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Row(
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Generating...',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Copy
                          GestureDetector(
                            onTap: _copyLink,
                            child: Opacity(
                              opacity: _isLinkLoaded ? 1.0 : 0.5,
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
                          ),
                          const SizedBox(width: 8),
                          // Share
                          GestureDetector(
                            onTap: _shareLink,
                            child: Opacity(
                              opacity: _isLinkLoaded ? 1.0 : 0.5,
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
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

// ✅ FIX UI 2: Update Helper dengan parameter baru & barrier color
void showTripCreatedSheet(
  BuildContext context, {
  required int tripId, // Tambah ini
  required String tripName,
  required String tripEmoji,
  required List<Map<String, dynamic>> participants,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor:
        Colors.black54, // ✅ Ini yang bikin background belakang jadi gelap
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => TripCreatedSheet(
      tripId: tripId,
      tripName: tripName,
      tripEmoji: tripEmoji,
      participants: participants,
    ),
  );
}
