import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:triva_app/features/profile/profile_page.dart';
import '../../../core/theme/app_colors.dart';
import '../trip_detail/trip_detail_page.dart';
import 'join_trip_sheet.dart';
import 'create_trip_sheet.dart';
import '../../../core/services/trip_service.dart';

class TripsListPage extends StatefulWidget {
  const TripsListPage({super.key});

  @override
  State<TripsListPage> createState() => _TripsListPageState();
}

class _TripsListPageState extends State<TripsListPage> {
  // ✅ SETUP CONTROLLER SESUAI FILE LOCAL KAMU
  late final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(
        // 1. LOGIC MENENTUKAN HALAMAN BERIKUTNYA
        getNextPageKey: (state) {
          if (state.keys == null || state.keys!.isEmpty) return 1;
          final lastPageItems = state.pages?.last;
          if (lastPageItems == null || lastPageItems.length < 10) return null;
          return state.keys!.last + 1;
        },

        // 2. LOGIC MENGAMBIL DATA DARI API
        fetchPage: (pageKey) async {
          try {
            final newTrips = await TripService().getTrips(page: pageKey);
            return newTrips;
          } catch (error) {
            throw error;
          }
        },
      );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void _refreshList() => _pagingController.refresh();

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.4),
        surfaceTintColor: AppColors.background,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Image.asset(
            'lib/assets/images/logo_triva.png',
            height: 32,
            errorBuilder: (c, e, s) => const Text(
              'Triva',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.trivaBlue,
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ),
              icon: const Icon(
                Icons.face_5_rounded,
                size: 25,
                color: AppColors.trivaBlue,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTripActionsSheet(context),
        // Shape "Squircle" (kotak sangat bulat) lebih gemas dibanding bulat total
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: AppColors.trivaBlue,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _pagingController.refresh(),
        color: AppColors.trivaBlue,
        child: PagingListener(
          controller: _pagingController,
          builder: (context, state, fetchNextPage) {
            return PagedListView<int, Map<String, dynamic>>(
              state: state,
              fetchNextPage: fetchNextPage,
              padding: const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                100,
              ), // Spasi bawah biar lega
              builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                itemBuilder: (context, item, index) =>
                    _TripCard(trip: item, formatCurrency: _formatCurrency),
                noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
                firstPageProgressIndicatorBuilder: (_) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  // --- UI WIDGETS ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'lib/assets/images/smile_icon.png',
            height: 70,
            errorBuilder: (c, o, s) => const Icon(
              Icons.sentiment_satisfied,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
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
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'Connection Failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your internet.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _refreshList,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.trivaBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showTripActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TripActionsSheet(onTripCreated: _refreshList),
    );
  }
}

// --- CLASS PENDUKUNG ---

class _TripActionsSheet extends StatelessWidget {
  final VoidCallback? onTripCreated;
  const _TripActionsSheet({this.onTripCreated});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                showCreateTripSheet(context, onSuccess: onTripCreated);
              },
            ),
            const SizedBox(height: 12),
            _TripActionCard(
              emoji: '🔗',
              title: 'Join an existing group trip',
              subtitle: 'Use an invite link from your friend.',

              onTap: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();

                final result = await showJoinTripSheet(context);

                if (result != null && result is Map<String, dynamic>) {
                  if (result.containsKey('error')) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(result['error']),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Berhasil bergabung ke ${result['name']}!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  // Navigasi ke detail
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => TripDetailPage(
                        tripId: result['id'],
                        tripName: result['name'],
                        coverUrl: result['cover_url'],
                      ),
                    ),
                  );

                  onTripCreated?.call();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TripActionCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;
  const _TripActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ✅ 1. TRIP CARD DENGAN INISIAL (AVATAR)
class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final Function(num) formatCurrency;

  const _TripCard({required this.trip, required this.formatCurrency});

  // ✅ Helper: Mendapatkan Inisial Nama (Misal: "Bali Trip" -> "BT")
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    // Pecah berdasarkan spasi
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';

    // Ambil huruf pertama kata pertama
    String initials = words[0][0];

    // Jika ada kata kedua, ambil huruf pertamanya juga
    if (words.length > 1) {
      initials += words[1][0];
    }

    return initials.toUpperCase();
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null || start.isEmpty) return 'No dates';
    try {
      final startDate = DateTime.parse(start);
      final fmt = DateFormat('d MMM');
      final startStr = fmt.format(startDate);

      if (end != null && end.isNotEmpty) {
        final endDate = DateTime.parse(end);
        final endStr = fmt.format(endDate);
        if (startStr != endStr) {
          return '$startStr - $endStr';
        }
      }
      return startStr;
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? coverUrl = trip['cover_url'];
    final String name = trip['name'] ?? 'Trip';
    final int membersCount = trip['members_count'] ?? 1;
    final dynamic rawTotal = trip['total_spent'];
    final num totalSpent = num.tryParse(rawTotal?.toString() ?? '0') ?? 0;

    final dateText = _formatDateRange(trip['start_date'], trip['end_date']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailPage(
              tripId: trip['id'],
              tripName: name,
              coverUrl: coverUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ KOTAK GAMBAR / INISIAL (KIRI)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                // Background abu jika gambar, biru muda jika inisial
                color: coverUrl != null && coverUrl.isNotEmpty
                    ? Colors.grey[100]
                    : AppColors.trivaBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Jika link gambar rusak, fallback ke Inisial
                          return Center(
                            child: Text(
                              _getInitials(name),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.trivaBlue,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      // ✅ TAMPILKAN INISIAL (AVATAR)
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.trivaBlue,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 16),

            // ✅ INFO TRIP (KANAN)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.trivaBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$membersCount Members • ${formatCurrency(totalSpent)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
