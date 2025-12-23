import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../trip_detail/trip_detail_page.dart'; // Sesuaikan path ini
import 'join_trip_sheet.dart';
import 'create_trip_sheet.dart';

class TripsListPage extends StatefulWidget {
  const TripsListPage({super.key});

  @override
  State<TripsListPage> createState() => _TripsListPageState();
}

class _TripsListPageState extends State<TripsListPage> {
  // Controller untuk pagination
  late final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(
    getNextPageKey: (state) =>
        state.keys?.isEmpty ?? true ? 1 : null, // Hanya fetch page 1 untuk mock single-page
    fetchPage: _fetchPage,
  );

  // Mock Data (Sesuai payload yang kamu berikan)
  final List<Map<String, dynamic>> _mockTrips = [
    {
      "id": 1,
      "name": "Venice",
      "description": "Liburan akhir tahun",
      "currency_code": "IDR",
      "start_date": "2025-12-01",
      "end_date": "2025-12-05",
      "members_count": 5,
      "activities_count": 3,
      "total_spent": 15800000,
      "cover_url": "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400",
      "my_balance": 4400000
    },
  ];

  @override
  void initState() {
    super.initState();
    // Tidak perlu addPageRequestListener lagi—fetchPage ditangani di constructor
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int pageKey) async {
    try {
      // Simulasi delay API
      await Future.delayed(const Duration(milliseconds: 500));

      // Karena ini mock, kita anggap cuma ada 1 halaman.
      // Jika pageKey > 1, return empty.
      if (pageKey > 1) {
        return [];
      } else {
        // Load mock data
        return _mockTrips;

        // JIKA INGIN TES EMPTY STATE:
        // return [];
      }
    } catch (error) {
      rethrow; // Biarkan error ditangani oleh builder delegate
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTripActionsSheet(context),
        shape: const CircleBorder(),
        backgroundColor: AppColors.trivaBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'lib/assets/images/logo_triva.png', // Pastikan path asset benar
                  height: 32, // Ukuran disesuaikan agar proporsional
                ),
              ),
            ),

            const SizedBox(height: 24),

            // List Content
            Expanded(
              child: PagingListener(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) => PagedListView<int, Map<String, dynamic>>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                    itemBuilder: (context, item, index) => _TripCard(
                      trip: item,
                      formatCurrency: _formatCurrency,
                    ),
                    // Tampilan saat list kosong
                    noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(),
                    // noItemsFoundIndicatorBuilder: (context) => const EmptyStateWidget(
                    //   title: 'No trips yet.',
                    //   subtitle: 'Tap + to create your first trip.',
                    //   // bottomPadding bisa disesuaikan agar tidak terlalu bawah
                    //   bottomPadding: 100,
                    // ),
                    firstPageProgressIndicatorBuilder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                    // Opsional: Tambahkan error handler jika diperlukan
                    // firstPageErrorIndicatorBuilder: (context) => Center(child: Text('Error: ${state.error}')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'lib/assets/images/smile_icon.png',
            height: 70,
            errorBuilder: (c, o, s) => const Icon(Icons.sentiment_satisfied, size: 60, color: Colors.grey),
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
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 100), // Offset ke atas sedikit
        ],
      ),
    );
  }

  // Bottom Sheet Logic (Sama seperti sebelumnya)
  void _showTripActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (ctx) => const _TripActionsSheet(),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final Function(num) formatCurrency;

  const _TripCard({
    required this.trip,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Trip
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailPage(
              tripId: trip['id'],
              tripName: trip['name'],
              coverUrl: trip['cover_url'], // Tambahkan ini
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
          // Opsional: Shadow tipis
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Trip Image / Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.trivaBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: trip['cover_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(trip['cover_url'], fit: BoxFit.cover),
                    )
                  : Icon(Icons.landscape, color: AppColors.trivaBlue, size: 30),
            ),
            const SizedBox(width: 16),

            // Trip Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip['members_count']} Members • ${formatCurrency(trip['total_spent'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(Icons.chevron_right, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

// ... _TripActionsSheet & _TripActionCard code (Sama persis seperti code kamu sebelumnya) ...
class _TripActionsSheet extends StatelessWidget {
  const _TripActionsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
            ),
            _TripActionCard(
              emoji: '🚀', title: 'Start a new group trip', subtitle: 'Create a trip and invite your friends.',
              onTap: () { Navigator.pop(context); showCreateTripSheet(context); },
            ),
            const SizedBox(height: 12),
            _TripActionCard(
              emoji: '🔗', title: 'Join an existing group trip', subtitle: 'Use an invite link from your friend.',
              onTap: () { Navigator.pop(context); showJoinTripSheet(context); },
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
  const _TripActionCard({required this.emoji, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}