import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:url_launcher/url_launcher.dart'; // Untuk buka WA
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';

class ShareTripSheet extends StatefulWidget {
  final int tripId;
  final String tripName;
  final List<dynamic> members;

  const ShareTripSheet({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.members,
  });

  @override
  State<ShareTripSheet> createState() => _ShareTripSheetState();
}

class _ShareTripSheetState extends State<ShareTripSheet> {
  bool _isLoadingLink = true;
  String? _shareUrl;
  String? _errorMessage;

  // ✅ STATE BARU: Menyimpan ID member yang SUDAH dikirimi pesan
  final Set<dynamic> _sentToMembers = {};

  @override
  void initState() {
    super.initState();
    _generateLink();
  }

  Future<void> _generateLink() async {
    try {
      final url = await TripService().getShareLink(widget.tripId);
      if (mounted) {
        setState(() {
          _shareUrl = url;
          _isLoadingLink = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to generate link.";
          _isLoadingLink = false;
        });
      }
    }
  }

  void _copyLink() {
    if (_shareUrl == null) return;
    Clipboard.setData(ClipboardData(text: _shareUrl!));

    // Ambil Overlay State sebelum pop
    final overlay = Overlay.of(context);
    Navigator.pop(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: MediaQuery.of(context).size.width / 2 - 75,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Link copied',
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
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  // ✅ Update: Tambahkan parameter memberId untuk tracking
  Future<void> _sendToWhatsApp(
    String phoneNumber,
    String name,
    dynamic memberId,
  ) async {
    if (_shareUrl == null) return;

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final message =
        "Hai $name! Cek ringkasan trip *${widget.tripName}* kita di sini:\n$_shareUrl";
    final url = Uri.parse(
      "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch';
      }

      // ✅ Tandai member ini sudah dikirim
      setState(() {
        _sentToMembers.add(memberId);
      });
    } catch (e) {
      debugPrint("WA Launch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Share Trip Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoadingLink
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION A: COPY LINK
                        const Text(
                          "Public Link",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _shareUrl ?? 'Generating...',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: _copyLink,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.trivaBlue,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("COPY"),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // SECTION B: DIRECT WHATSAPP
                        Row(
                          children: [
                            const Text(
                              "Send directly to",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            if (widget.members.length > 2)
                              Text(
                                "Tap one by one",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ...widget.members.map((member) {
                          final memberId = member['id']; // ID unik member
                          final isGuest = member['user'] == null;
                          final name = isGuest
                              ? member['guest_name']
                              : member['user']['name'];
                          final contact = isGuest
                              ? member['guest_contact']
                              : null;
                          final hasContact =
                              contact != null && contact.toString().isNotEmpty;

                          // ✅ Cek apakah sudah pernah dikirim
                          final isSent = _sentToMembers.contains(memberId);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isGuest
                                        ? Colors.orange.withOpacity(0.1)
                                        : AppColors.trivaBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isGuest
                                            ? Colors.orange
                                            : AppColors.trivaBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        isGuest ? "Guest" : "Member",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (hasContact)
                                  // ✅ Tombol WA berubah tampilan jika sudah dikirim
                                  isSent
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "Sent",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: () => _sendToWhatsApp(
                                            contact,
                                            name,
                                            memberId,
                                          ),
                                          icon: const Icon(
                                            Icons.send_rounded,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Send via WhatsApp',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.green
                                                .withOpacity(0.1),
                                          ),
                                        )
                                else
                                  Text(
                                    "No contact",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[300],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

void showShareTripSheet(
  BuildContext context, {
  required int tripId,
  required String tripName,
  required List<dynamic> members,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) =>
        ShareTripSheet(tripId: tripId, tripName: tripName, members: members),
  );
}