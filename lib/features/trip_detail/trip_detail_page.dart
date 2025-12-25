import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  double _myExpenses = 0; // ✅ Total pengeluaran pribadi

  // Logic User Identity
  int? _currentMemberId; // ✅ ID Member kita di trip ini

  // Data Balance Real (Filtered untuk User Login)
  List<Map<String, dynamic>> _myBalance = [];

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

    try {
      final tripService = TripService();
      final data = await tripService.getTripDetail(widget.tripId);

      // 1. Ambil Data User yang Login dari SharedPreferences untuk identifikasi diri
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_data');
      int? currentUserId;

      if (userString != null) {
        final userJson = jsonDecode(userString);
        currentUserId = userJson['id'];
      }

      if (mounted) {
        setState(() {
          if (data != null) {
            _tripData = data;
            _members = data['members'] ?? [];
            _activities =
                data['transactions'] ??
                []; // Pastikan backend kirim transaksi lengkap

            // 2. Cari Member ID Kita di Trip Ini
            if (currentUserId != null) {
              final myMemberData = _members.firstWhere(
                (m) =>
                    m['user_id'] == currentUserId ||
                    (m['user'] != null && m['user']['id'] == currentUserId),
                orElse: () => null,
              );

              if (myMemberData != null) {
                _currentMemberId = myMemberData['id'];
              }
            }

            // 3. Hitung Total Expenses (Global Trip)
            _totalExpenses = _activities.fold(0.0, (sum, item) {
              final amt =
                  double.tryParse(item['total_amount'].toString()) ?? 0.0;
              return sum + amt;
            });

            // 4. Hitung My Expenses (Personal)
            _myExpenses = 0;
            if (_currentMemberId != null) {
              for (var activity in _activities) {
                // Backend harus kirim 'splits' di dalam object transaction
                if (activity['splits'] != null) {
                  for (var split in activity['splits']) {
                    if (split['member_id'] == _currentMemberId) {
                      _myExpenses +=
                          double.tryParse(split['amount'].toString()) ?? 0.0;
                    }
                  }
                }
              }
            }

            _tripData['total_expenses'] = _totalExpenses;
            _tripData['activities_count'] = _activities.length;
            _tripData['members_count'] = _members.length;
          }
        });

        // 5. ✅ LOGIC BARU: Ambil My Balances dari API (Sudah dihitung backend)
        if (_currentMemberId != null) {
          final balances = await tripService.getMyBalances(widget.tripId);

          setState(() {
            _myBalance = balances.map((item) {
              // Mapping response API ke format UI
              // API Backend return: type = 'you_owe' (merah) atau 'owes_you' (hijau)
              // UI Flutter expect: type = 'owe' (merah) atau 'receivable' (hijau)

              final isOwe = item['type'] == 'you_owe';

              return {
                'type': isOwe ? 'owe' : 'receivable',
                'name': item['name'],
                'amount': double.tryParse(item['amount'].toString()) ?? 0.0,
                'status': item['status'], // 'paid' atau 'unpaid'
                'raw_data': item, // Simpan data asli untuk payload settlement
              };
            }).toList();

            _isLoading = false;
          });
        } else {
          setState(() {
            _myBalance = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching trip data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Fungsi Bayar Hutang Langsung (Tombol Pay)
  Future<void> _payDebt(Map<String, dynamic> transaction) async {
    try {
      // 1. Validasi Data Sebelum Kirim
      final fromId = transaction['from_member_id'];
      final toId = transaction['to_member_id'];

      // Pastikan amount bersih dari karakter aneh
      final rawAmount = transaction['amount'].toString().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final amount = double.tryParse(rawAmount) ?? 0.0;

      if (fromId == null || toId == null) {
        throw Exception("Invalid member ID");
      }

      // Tampilkan loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing...'),
          duration: Duration(milliseconds: 500),
        ),
      );

      // 2. Panggil Service
      final success = await TripService().createSettlement(
        widget.tripId,
        int.parse(fromId.toString()), // Paksa ke int
        int.parse(toId.toString()), // Paksa ke int
        amount,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as paid!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTripData();
      } else {
        throw Exception("Server returned failed status");
      }
    } catch (e) {
      debugPrint("🔥 Error paying debt: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  // ✅ PERBAIKAN: Kirim ID dan Name
                  final List<Map<String, dynamic>> memberForActivity = _members
                      .map((m) {
                        final memberId = m['id'];

                        final name = m['user'] != null
                            ? m['user']['name']
                            : m['guest_name'];

                        return {'id': memberId, 'name': name.toString()};
                      })
                      .toList();

                  navigateToAddActivityPage(
                    context,
                    tripId: widget.tripId,
                    members: memberForActivity,
                    onActivityAdded: (activityData) {
                      _fetchTripData(); // Refresh setelah sukses
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

  // ✅ LOGIC BARU: EXPENSES TAB (PERSONAL DASHBOARD)
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
                  amount: _myExpenses, // Value dari variabel state
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
            onTap: () async {
              // ✅ Navigasi ke Summary & Refresh saat kembali
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SummaryPage(tripId: widget.tripId),
                ),
              );
              _fetchTripData();
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

          // ✅ LIST PENDING BALANCES (DATA DARI API)
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
          else ...[
            const Text(
              'My Balance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ..._myBalance.map((item) {
              final isOwe = item['type'] == 'owe';
              final isPaid = item['status'] == 'paid'; // ✅ Cek status dari API

              // Jika Paid, warna jadi hijau/abu, jika belum lunas ikuti tipe hutang
              final color = isPaid
                  ? Colors.green
                  : (isOwe ? Colors.red : Colors.green);

              final label = isOwe ? "You owe" : "Owes you";
              final displayAmount = isPaid
                  ? "Paid" // Atau tampilkan angka 0
                  : _formatCurrency(item['amount']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  // Border merah hanya jika Saya Hutang & Belum Lunas
                  border: (isOwe && !isPaid)
                      ? Border.all(color: Colors.red.withOpacity(0.1))
                      : null,
                ),
                child: Row(
                  children: [
                    // Avatar Inisial
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isPaid
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: color,
                              ) // ✅ Icon Ceklis jika lunas
                            : Text(
                                item['name'][0].toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$label ${item['name']}",
                            style: TextStyle(
                              fontSize:
                                  13, // Sedikit dinaikkan biar enak dibaca
                              color:
                                  color, // Warna tetap dinamis (Merah/Hijau) sesuai status
                              fontWeight: FontWeight
                                  .normal, // Tidak ada yang bold, semua sama rata
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayAmount,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isPaid ? TextDecoration.none : null,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LOGIKA TOMBOL (Sisi Kanan)
                    if (isPaid)
                      // ✅ Tampilan Jika SUDAH LUNAS (Paid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isOwe)
                      // ✅ Tombol Pay (Hanya jika Saya Hutang & Belum Lunas)
                      ElevatedButton(
                        onPressed: () => _payDebt(item['raw_data']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.trivaBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Set as Paid',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      // ✅ Label Unpaid (Jika Orang Hutang ke Saya)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Unpaid',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
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
