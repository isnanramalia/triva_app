import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';
import 'edit_activity_page.dart';

class ActivityDetailPage extends StatefulWidget {
  final List<dynamic> activities;
  final int initialIndex;
  final List<dynamic> members;
  final int tripId;

  const ActivityDetailPage({
    super.key,
    required this.activities,
    required this.initialIndex,
    required this.members,
    required this.tripId,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late int _currentIndex;
  Map<String, dynamic>? _activityDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchDetail();
  }

  // --- NAVIGATION LOGIC ---

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.activities.length - 1;

  void _goNext() {
    if (_hasNext) {
      setState(() => _currentIndex++);
      _fetchDetail();
    }
  }

  void _goPrev() {
    if (_hasPrev) {
      setState(() => _currentIndex--);
      _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activity = widget.activities[_currentIndex];
      final int tripId = activity['trip_id'];
      final int activityId = activity['id'];

      final data = await TripService().getTransactionDetail(tripId, activityId);

      if (mounted) {
        if (data != null) {
          setState(() {
            _activityDetail = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Activity not found.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Connection error.";
          _isLoading = false;
        });
      }
    }
  }

  // --- UI HELPERS ---

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text(
        'Activities',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      leadingWidth: 100,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: const Row(
          children: [
            SizedBox(width: 8),
            Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.trivaBlue,
            ),
            Text(
              ' Details',
              style: TextStyle(color: AppColors.trivaBlue, fontSize: 17),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PREVIOUS BUTTON
            IconButton(
              onPressed: _hasPrev ? _goPrev : null,
              icon: Icon(
                Icons.chevron_left,
                color: _hasPrev
                    ? AppColors.trivaBlue
                    : AppColors.trivaBlue.withOpacity(0.2),
                size: 32,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            // NEXT BUTTON
            IconButton(
              onPressed: _hasNext ? _goNext : null,
              icon: Icon(
                Icons.chevron_right,
                color: _hasNext
                    ? AppColors.trivaBlue
                    : AppColors.trivaBlue.withOpacity(0.2),
                size: 32,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            // EDIT BUTTON
            TextButton(
              onPressed: _activityDetail == null
                  ? null
                  : () async {
                      // ✅ Navigasi ke halaman edit (Pastikan sudah import EditActivityPage)
                      final bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => EditActivityPage(
                            activity: _activityDetail!,
                            members: widget
                                .members, // ✅ Sekarang kita punya data member yang benar
                            tripId: widget.tripId,
                          ),
                        ),
                      );

                      if (updated == true) {
                        _fetchDetail(); // Refresh data detail setelah edit sukses
                      }
                    },
              child: const Text(
                'Edit',
                style: TextStyle(color: AppColors.trivaBlue, fontSize: 17),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_errorMessage != null) return _buildErrorState();

    final activity = _activityDetail!;
    final dateStr = activity['date'] != null
        ? DateFormat(
            'EEEE, d MMMM yyyy',
          ).format(DateTime.parse(activity['date']))
        : 'Unknown Date';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // 1. Hero Header Card
          Container(
            width: double.infinity,
            // ✅ Padding vertikal dikurangi dari 32 ke 20
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Biar container menyesuaikan isi
              children: [
                // 1. Emoji (Ukuran dikecilkan sedikit dari 48 ke 36)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    activity['emoji'] ?? '📝',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Judul
                Text(
                  activity['title'] ?? 'Activity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20, // Turun sedikit dari 22
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 3. Tanggal
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                // 4. Divider (Padding dikurangi drastis dari 20 ke 12)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(indent: 60, endIndent: 60, thickness: 0.5),
                ),

                // 5. Total Amount Section
                const Text(
                  "TOTAL AMOUNT",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(
                    double.tryParse(activity['total_amount'].toString()) ?? 0,
                  ),
                  style: const TextStyle(
                    fontSize: 28, // Dari 32 ke 28 agar lebih proporsional
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader("PAID BY"),
          _buildDetailBox(items: _getPaidByList()),

          const SizedBox(height: 24),

          _buildSectionHeader("SPLIT DETAILS"),
          _buildDetailBox(items: _getSplitsList(), isSplit: true),

          const SizedBox(height: 40),
          Text(
            "Created by ${activity['created_by']?['user']?['name'] ?? 'System'}",
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox({
    required List<Map<String, dynamic>> items,
    bool isSplit = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      (isSplit ? "- " : "") + _formatCurrency(item['amount']),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSplit
                            ? Colors.red.shade700
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border.withOpacity(0.3),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Something went wrong",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(onPressed: _fetchDetail, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPaidByList() {
    if (_activityDetail == null || _activityDetail!['paid_by'] == null)
      return [];
    final paidBy = _activityDetail!['paid_by'];
    return [
      {
        "name": paidBy['user']?['name'] ?? paidBy['guest_name'] ?? 'Guest',
        "amount":
            double.tryParse(_activityDetail!['total_amount'].toString()) ?? 0.0,
      },
    ];
  }

  List<Map<String, dynamic>> _getSplitsList() {
    if (_activityDetail == null || _activityDetail!['splits'] == null)
      return [];
    return (_activityDetail!['splits'] as List).map((split) {
      final member = split['member'];
      return {
        "name": member?['user']?['name'] ?? member?['guest_name'] ?? 'Guest',
        "amount": double.tryParse(split['amount'].toString()) ?? 0.0,
      };
    }).toList();
  }
}
