import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'activity_detail_page.dart';
import 'summary_page.dart';
import '../../core/widgets/add_member_sheet.dart';
import 'add_activity_page.dart';
import '../../../core/services/trip_service.dart';

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
  bool _isLoading = true;

  // Data Trip Real
  Map<String, dynamic> _tripData = {};
  List<dynamic> _members = [];
  List<dynamic> _activities = [];

  // Expenses Calculation
  double _totalExpenses = 0;

  // Mock My Balance
  final List<Map<String, dynamic>> _myBalance = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set data awal
    _tripData = {
      "id": widget.tripId,
      "name": widget.tripName,
      "cover_url": widget.coverUrl,
      "members_count": 0,
      "activities_count": 0,
      "my_expenses": 0,
      "total_expenses": 0,
    };

    _fetchTripData();
  }

  Future<void> _fetchTripData() async {
    setState(() => _isLoading = true);

    final data = await TripService().getTripDetail(widget.tripId);

    if (mounted) {
      setState(() {
        if (data != null) {
          _tripData = data;
          _members = data['members'] ?? [];
          _activities = data['transactions'] ?? [];

          _totalExpenses = _activities.fold(0.0, (sum, item) {
            final amt = double.tryParse(item['total_amount'].toString()) ?? 0.0;
            return sum + amt;
          });

          _tripData['total_expenses'] = _totalExpenses;
          _tripData['activities_count'] = _activities.length;
          _tripData['members_count'] = _members.length;
        }
        _isLoading = false;
      });
    }
  }

  // ✅ SHEET: LIST MEMBER
  void _showMembersListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trip Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddMemberInput();
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.trivaBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _members.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final isGuest = member['user'] == null;
                  final name = isGuest
                      ? member['guest_name']
                      : member['user']['name'];
                  final role = member['role'];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isGuest
                            ? Colors.orange.withOpacity(0.1)
                            : AppColors.trivaBlue.withOpacity(0.1),
                        child: Text(
                          name.toString()[0].toUpperCase(),
                          style: TextStyle(
                            color: isGuest
                                ? Colors.orange
                                : AppColors.trivaBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (role == 'admin') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        isGuest ? 'Guest (No Account)' : 'Registered User',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: isGuest
                          ? IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Edit feature coming soon!'),
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ LOGIC ADD MEMBER
  void _showAddMemberInput() {
    final existingNames = _members.map<String>((m) {
      if (m['user'] != null) return m['user']['name'].toString();
      return m['guest_name'].toString();
    }).toList();

    showAddMemberSheet(
      context,
      excludeNames: existingNames,
      onAddMember: (newMember) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adding member...'),
            duration: Duration(seconds: 1),
          ),
        );

        final success = await TripService().addMemberToTrip(
          widget.tripId,
          newMember,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Member added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchTripData();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add member'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    String initials = words[0][0];
    if (words.length > 1) initials += words[1][0];
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
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
                            const Text(
                              'Trips',
                              style: TextStyle(
                                fontSize: 17,
                                color: AppColors.trivaBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _showMembersListSheet,
                        icon: const Icon(
                          Icons.group_add,
                          size: 26,
                          color: AppColors.trivaBlue,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ SECTION TRIP INFO (OVERLAY STYLE)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                height: 220, // Tinggi banner
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. IMAGE BACKGROUND
                      _buildCoverImage(),

                      // 2. GRADIENT OVERLAY (Supaya teks terbaca)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7), // Hitam di bawah
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),

                      // 3. TEXT CONTENT (Positioned)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Judul Trip
                            Text(
                              _tripData['name'] ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 26, // Lebih besar
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Text Putih
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Badge Stats (Member & Activities)
                            Row(
                              children: [
                                _buildStatBadge(
                                  Icons.people,
                                  '${_tripData['members_count'] ?? 0} Members',
                                  isOverlay: true, // Style khusus overlay
                                ),
                                const SizedBox(width: 8),
                                _buildStatBadge(
                                  Icons.local_activity,
                                  '${_tripData['activities_count'] ?? 0} Activities',
                                  isOverlay: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- TAB BAR ---
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

            // --- TAB CONTENT ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildActivitiesTab(), _buildExpensesTab()],
                    ),
            ),
          ],
        ),
      ),

      // Floating Action Button
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
                  final List<Map<String, dynamic>> memberForActivity = _members
                      .map((m) {
                        final name = m['user'] != null
                            ? m['user']['name']
                            : m['guest_name'];
                        return {'name': name.toString()};
                      })
                      .toList();

                  navigateToAddActivityPage(
                    context,
                    tripId: widget.tripId,
                    members: memberForActivity,
                    onActivityAdded: (activityData) {
                      _fetchTripData();
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

  // ✅ Helper: Build Cover Image (Network / Initials)
  Widget _buildCoverImage() {
    if (_tripData['cover_url'] != null &&
        _tripData['cover_url'].toString().isNotEmpty) {
      return Image.network(
        _tripData['cover_url'],
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: AppColors.trivaBlue,
          child: Center(
            child: Text(
              _getInitials(_tripData['name'] ?? ''),
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white30,
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        color: AppColors.trivaBlue,
        child: Center(
          child: Text(
            _getInitials(_tripData['name'] ?? ''),
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.white30, // Putih transparan biar elegan
            ),
          ),
        ),
      );
    }
  }

  // ✅ Helper: Badge Stats (Support Overlay Style)
  Widget _buildStatBadge(IconData icon, String text, {bool isOverlay = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // Kalau overlay: background putih transparan (glassmorphism)
        color: isOverlay ? Colors.white.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: isOverlay
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isOverlay ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOverlay ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            const Text(
              'No activities yet',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ExpenseSummaryCard(
                  title: 'My Expenses',
                  amount: 0,
                  formatCurrency: _formatCurrency,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExpenseSummaryCard(
                  title: 'Total Expenses',
                  amount: _totalExpenses,
                  formatCurrency: _formatCurrency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummaryPage()),
            ),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_myBalance.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No pending balances',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'My Balance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
                    '${DateFormat('d MMM').format(DateTime.parse(activity['date']))}',
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
