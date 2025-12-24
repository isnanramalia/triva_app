import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'activity_detail_page.dart';
import 'summary_page.dart';
import '../../core/widgets/add_member_sheet.dart'; // Pastikan path ini benar atau comment jika belum ada file-nya
import 'add_activity_page.dart';

class TripDetailPage extends StatefulWidget {
  final int tripId;
  final String tripName;
  final String? coverUrl;

  const TripDetailPage({
    super.key,
    required this.tripId,
    required this.tripName,
    this.coverUrl,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingActivities = true;
  late Map<String, dynamic> _tripData;

  // Mock trip summary
  // Map<String, dynamic> _tripData = {
  //   "id": 1,
  //   "name": "Venice",
  //   "members_count": 5,
  //   "activities_count": 3,
  //   "cover_url":
  //       "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400",
  //   "total_expenses": 17300000,
  //   "my_expenses": 3460000,
  // };

  // Mock members
  List<Map<String, dynamic>> _members = [
    {'name': 'Neena', 'username': '@neena', 'isAdmin': true},
    {'name': 'Ahmad', 'username': '@ahmad', 'isAdmin': false},
    {'name': 'Budi', 'username': '@budi', 'isAdmin': false},
    {'name': 'Amanda', 'username': '@amanda', 'isAdmin': false},
    {'name': 'Risa', 'username': '@risa', 'isAdmin': false},
  ];

  // Activities list
  List<Map<String, dynamic>> _activities = [];

  // My Balance Data
  List<Map<String, dynamic>> _myBalance = [
    {"description": "You owed Ahmad", "amount": 13000000, "status": "unpaid"},
    {
      "description": "Amanda owes You",
      "amount": 13000000,
      "status": "not_paid_yet",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Init data dengan gambar dari parameter widget
    _tripData = {
      "id": widget.tripId,
      "name": widget.tripName,
      "members_count": 5,
      "activities_count": 3,
      "cover_url": widget.coverUrl, // Gunakan gambar yang dikirim dari list
      "total_expenses": 17300000,
      "my_expenses": 3460000,
    };

    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _activities = [
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

        // Recalculate totals based on loaded activities
        _calculateTotals();

        _isLoadingActivities = false;
      });
    }
  }

  void _calculateTotals() {
    // Hitung ulang total expenses dari activities
    double total = 0.0;
    for (var act in _activities) {
      total += (act['total_amount'] as num).toDouble();
    }

    // Update state trip data
    _tripData['total_expenses'] = total;
    _tripData['activities_count'] = _activities.length;

    // (Opsional) Di sini kamu bisa menambahkan logika untuk update _myBalance
    // secara dinamis berdasarkan "Split" dari activity, tapi untuk sekarang
    // kita pakai mock _myBalance dulu agar UI muncul.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 40, // Tinggi fix agar layout stabil
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Kiri: Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.trivaBlue),
                            const SizedBox(width: 4),
                            Text('Trips', style: TextStyle(fontSize: 17, color: AppColors.trivaBlue)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Tengah: Judul
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 17, 
                        fontWeight: FontWeight.w600, 
                        color: AppColors.textPrimary
                      ),
                    ),

                    // Kanan: Add Member Icon
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          // showAddMemberSheet(...);
                        },
                        icon: const Icon(Icons.person_add, size: 24, color: AppColors.trivaBlue),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Trip Info ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _tripData['cover_url'] != null
                          ? Image.network(
                              _tripData['cover_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppColors.trivaBlue.withOpacity(0.1),
                                child: Icon(Icons.landscape, color: AppColors.trivaBlue, size: 40),
                              ),
                            )
                          : Container(
                              color: AppColors.trivaBlue.withOpacity(0.1),
                              child: Icon(Icons.landscape, color: AppColors.trivaBlue, size: 40),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.tripName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
                children: [_buildActivitiesTab(), _buildExpensesTab()],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.border.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  navigateToAddActivityPage(
                    context,
                    tripId: widget.tripId,
                    members: _members,
                    onActivityAdded: (activityData) {
                      setState(() {
                        // 1. Add new activity
                        _activities.add({
                          'id': DateTime.now().millisecondsSinceEpoch,
                          'title': activityData['title'],
                          'emoji': activityData['emoji'],
                          'date': activityData['date'],
                          'total_amount': activityData['amount'],
                          'paid_by_summary': activityData['paid_by'].map((p) => p['name']).join(', '),
                        });

                        // 2. Add dummy expense item so user sees change in Expenses tab
                        _myBalance.add({
                          "description":
                              "You paid for ${activityData['title']}",
                          "amount": activityData['amount'],
                          "status": "unpaid", // Mock status
                        });

                        // 3. Recalculate totals
                        _calculateTotals();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${activityData['title']} added!'),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Activity"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.trivaBlue,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _ActivityCard(
          activity: activity,
          formatCurrency: _formatCurrency,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailPage(
                  activityId: activity['id'],
                  activityData: activity,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    final hasExpenses = _myBalance.isNotEmpty;

    if (!hasExpenses) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No expenses yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Cards
          Row(
            children: [
              Expanded(child: _ExpenseSummaryCard(title: 'My Expenses', amount: _tripData['my_expenses'], formatCurrency: _formatCurrency)),
              const SizedBox(width: 12),
              Expanded(child: _ExpenseSummaryCard(title: 'Total Expenses', amount: _tripData['total_expenses'], formatCurrency: _formatCurrency)),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Link
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryPage())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Summary', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary.withOpacity(0.5)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text('My Balance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),

          // LIST ITEMS
          ..._myBalance.map((balance) {
            final isUnpaid = balance['status'] == 'unpaid';
            final isNotPaidYet = balance['status'] == 'not_paid_yet'; // Status orang lain
            final isPaid = balance['status'] == 'paid';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(balance['description'] ?? 'Expense', style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.7))),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(balance['amount'] ?? 0), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  
                  // Kanan: Tombol/Status (Konsisten dengan Summary Page)
                  if (isPaid)
                    OutlinedButton(
                      onPressed: () {}, // Action to unpay if needed
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    )
                  else if (isUnpaid)
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.trivaBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Set as Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    )
                  else if (isNotPaidYet)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Not paid yet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Widget Extract untuk Summary Card agar kode lebih rapi
class _ExpenseSummaryCard extends StatelessWidget {
  final String title;
  final num amount;
  final Function(num) formatCurrency;

  const _ExpenseSummaryCard({
    required this.title,
    required this.amount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(amount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
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
                    activity['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid by ${activity['paid_by_summary'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 13,
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
