import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class TripDetailPage extends StatefulWidget {
  final int tripId;
  final String tripName;

  const TripDetailPage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(
    getNextPageKey: (state) =>
        state.keys?.isEmpty ?? true ? 1 : null, // Hanya fetch page 1 untuk mock single-page
    fetchPage: _fetchActivities,
  );

  // Mock trip summary
  final Map<String, dynamic> _tripData = {
    "id": 1,
    "name": "Venice",
    "members_count": 5,
    "activities_count": 3,
    "cover_url": null, // Coba ganti URL gambar untuk test cover
  };

  // Mock activities (Tab 1)
  final List<Map<String, dynamic>> _mockActivities = [
    {
      "id": 10,
      "title": "Villa",
      "emoji": "🛏️",
      "date": "2025-12-01 13:00:00",
      "total_amount": 13000000,
      "paid_by_summary": "Ahmad, Budi",
    },
    {
      "id": 11,
      "title": "Gondola",
      "emoji": "🛶",
      "date": "2025-12-02 10:00:00",
      "total_amount": 1500000,
      "paid_by_summary": "Neena",
    },
    {
      "id": 12,
      "title": "Fine Dining",
      "emoji": "🥂",
      "date": "2025-12-02 19:00:00",
      "total_amount": 2800000,
      "paid_by_summary": "Risa",
    },
  ];

  // Mock Expenses / Settlements (Tab 2 - Sesuai Screenshot Settlement)
  final List<Map<String, dynamic>> _mockSettlements = [
    {"name": "Neena", "amount": -2600000}, // Hutang (Merah)
    {"name": "Ahmad", "amount": 4400000},  // Piutang (Hijau)
    {"name": "Budi", "amount": 3400000},
    {"name": "Amanda", "amount": -2600000},
    {"name": "Risa", "amount": -2600000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Tidak perlu addPageRequestListener lagi—fetchPage ditangani di constructor
  }

  Future<List<Map<String, dynamic>>> _fetchActivities(int pageKey) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (pageKey > 1) {
        return [];
      } else {
        return _mockActivities;
      }
    } catch (error) {
      rethrow; // Biarkan error ditangani oleh builder delegate
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0
    );
    return format.format(amount); // Otomatis handle minus sign
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header (Back & Title) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.trivaBlue),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      'Details',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Placeholder agar Title di tengah
                  const SizedBox(width: 20),
                  // Opsional: Tombol Edit/Setting di kanan
                  // IconButton(...)
                ],
              ),
            ),

            // --- Trip Info Card ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Trip Image
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.trivaBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _tripData['cover_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(_tripData['cover_url'], fit: BoxFit.cover),
                          )
                        : Image.network('https://img.icons8.com/color/96/mountain.png', width: 40), // Placeholder asset
                  ),
                  const SizedBox(height: 12),
                  // Trip Name
                  Text(
                    widget.tripName, // Gunakan nama dari parameter agar instant
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Stats
                  Text(
                    '${_tripData['members_count']} Members • ${_tripData['activities_count']} Activities',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Tab Bar ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200], // Background tab bar
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent, // Hilangkan garis bawah default
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Activities'),
                  Tab(text: 'Expenses'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Tab Views ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Activities List
                  PagingListener(
                    controller: _pagingController,
                    builder: (context, state, fetchNextPage) => PagedListView<int, Map<String, dynamic>>(
                      state: state,
                      fetchNextPage: fetchNextPage,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                        itemBuilder: (context, item, index) => _ActivityCard(
                          activity: item,
                          formatCurrency: _formatCurrency,
                          onTap: () {},
                        ),
                        noItemsFoundIndicatorBuilder: (ctx) => const Center(child: Text("No activities yet")),
                        // Opsional: Tambahkan error handler jika diperlukan
                        // firstPageErrorIndicatorBuilder: (context) => Center(child: Text('Error: ${state.error}')),
                      ),
                    ),
                  ),

                  // Tab 2: Expenses (Settlement) List
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Settlement Header
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text("Settlement", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: _mockSettlements.map((member) {
                            final amount = member['amount'] as int;
                            final isPositive = amount >= 0;
                            // Jika positif -> Hijau (+), Negatif -> Merah (-)
                            
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  title: Text(member['name'], style: const TextStyle(fontSize: 15)),
                                  trailing: Text(
                                    (isPositive ? '+ ' : '') + _formatCurrency(amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isPositive ? Colors.green : Colors.red,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                // Divider antar item, kecuali item terakhir
                                if (member != _mockSettlements.last)
                                  Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[100]),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Tombol Add Activity hanya di Tab Activities (bisa dihandle logic index tab)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             TextButton.icon(
                onPressed: () {
                  // TODO: Buka form Add Transaction
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Activity"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.trivaBlue,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
             ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String Function(num) formatCurrency;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.formatCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Emoji Box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  activity['emoji'] ?? '📝',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid by ${activity['paid_by_summary']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Amount & Chevron (Opsional, sesuai screenshot)
            Row(
              children: [
                // Jika ingin menampilkan amount di kanan:
                // Text(formatCurrency(activity['total_amount']), style: TextStyle(fontWeight: FontWeight.bold)),
                // SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.border),
              ],
            )
          ],
        ),
      ),
    );
  }
}