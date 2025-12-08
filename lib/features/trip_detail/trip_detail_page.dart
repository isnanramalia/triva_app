import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'activity_detail_page.dart';
import 'summary_page.dart';

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
        state.keys?.isEmpty ?? true ? 1 : null,
    fetchPage: _fetchActivities,
  );

  // Mock trip summary - DATA KONSISTEN
  final Map<String, dynamic> _tripData = {
    "id": 1,
    "name": "Venice",
    "members_count": 5,
    "activities_count": 3,
    "cover_url": "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400",
    "total_expenses": 17300000,
    "my_expenses": 3460000,
  };

  // Mock activities - FIX EMOJI ENCODING
  final List<Map<String, dynamic>> _mockActivities = [
    {
      "id": 10,
      "title": "Villa",
      "emoji": "🏛️",
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

  // Mock My Balance data
  final List<Map<String, dynamic>> _mockMyBalance = [
    {
      "description": "You owed Ahmad",
      "amount": 2600000,
      "status": "unpaid",
    },
    {
      "description": "Budi owes You",
      "amount": 860000,
      "status": "not_paid_yet",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      rethrow;
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
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button with Trips text
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: AppColors.trivaBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Trips',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.trivaBlue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
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
                  // Add Member Icon
                  IconButton(
                    onPressed: () {
                      // TODO: Open add member sheet
                    },
                    icon: const Icon(
                      Icons.person_add,
                      size: 24,
                      color: AppColors.trivaBlue,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _tripData['cover_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.trivaBlue.withValues(alpha: 0.1),
                            child: Icon(Icons.landscape, color: AppColors.trivaBlue, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Trip Name
                  Text(
                    widget.tripName,
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
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
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
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityDetailPage(
                                  activityId: item['id'],
                                  activityData: item,
                                ),
                              ),
                            );
                          },
                        ),
                        noItemsFoundIndicatorBuilder: (ctx) => const Center(child: Text("No activities yet")),
                      ),
                    ),
                  ),

                  // Tab 2: Expenses
                  _buildExpensesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             TextButton.icon(
                onPressed: () {
                  // TODO: Add Activity
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

  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Expenses & Total Expenses Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Expenses',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_tripData['my_expenses']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_tripData['total_expenses']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SummaryPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // My Balance Section
          const Text(
            'My Balance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // My Balance List
          ..._mockMyBalance.map((balance) {
            final isUnpaid = balance['status'] == 'unpaid';
            final isNotPaidYet = balance['status'] == 'not_paid_yet';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(balance['amount']),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnpaid)
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Set as paid
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.trivaBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Set as Paid',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (isNotPaidYet)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Not paid yet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 80),
        ],
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
            // Emoji (no background)
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Text(
                  activity['emoji'] ?? '📦',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
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
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
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