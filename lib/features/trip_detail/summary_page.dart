import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';
import '../../core/widgets/share_trip_sheet.dart'; // ✅ Pastikan import ini ada

class SummaryPage extends StatefulWidget {
  final int tripId;
  final String tripName;
  final List<dynamic> members;
  final int? currentUserId;
  final int? tripOwnerId;

  const SummaryPage({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.members,
    this.currentUserId,
    this.tripOwnerId,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isLoading = true;
  int? _currentMemberId;

  Map<String, dynamic> _tripData = {};

  List<dynamic> _overviewData = [];
  List<dynamic> _settlementTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    try {
      final data = await TripService().getSummary(widget.tripId);

      if (mounted && data != null) {
        setState(() {
          _tripData = data;
          _overviewData = data['overview'] ?? [];
          _settlementTransactions = data['settlements'] ?? [];

          final myData = _overviewData.firstWhere(
            (item) => item['is_current_user'] == true,
            orElse: () => null,
          );
          if (myData != null) {
            _currentMemberId = myData['member_id'];
          }

          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading summary: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount.abs());
  }

  Future<void> _payDebt(Map<String, dynamic> transaction) async {
    print("📦 DATA TRANSAKSI: $transaction");

    try {
      final fromId = transaction['from_member_id'];
      final toId = transaction['to_member_id'];
      final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      print("💰 Paying Amount: $amount (From: $fromId To: $toId)");
      if (fromId == null || toId == null) {
        // Jika ini muncul, cek log "DATA TRANSAKSI" di atas, pasti key-nya hilang
        throw Exception("Invalid member ID. Data: $transaction");
      }
      if (amount <= 0.01) {
        throw Exception("Invalid amount: $amount");
      }

      if (fromId == null || toId == null) throw Exception("Invalid ID");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing...'),
          duration: Duration(milliseconds: 500),
        ),
      );

      final success = await TripService().createSettlement(
        widget.tripId,
        int.parse(fromId.toString()),
        int.parse(toId.toString()),
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
        _fetchSummary();
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ LOGIC SHARE BARU: Panggil Sheet Canggih (Copy + WA)
  void _onSharePressed() {
    showShareTripSheet(
      context,
      tripId: widget.tripId,
      tripName: widget.tripName,
      members: widget.members,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ HEADER (Konsisten)
            _buildHeader(context),

            // ✅ CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- SECTION 1: OVERVIEW ---
                          const Text(
                            'Balance Overview',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildOverviewList(),

                          const SizedBox(height: 32),

                          // --- SECTION 2: SETTLEMENT ---
                          const Text(
                            'Settlement Plan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suggested payments to settle debts.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSettlementList(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
                  children: const [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.trivaBlue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Details',
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
              'Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _onSharePressed,
                icon: const Icon(Icons.ios_share, color: AppColors.trivaBlue),
                tooltip: 'Share Public Link',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewList() {
    // 1. Cek kondisi Overview Kosong
    if (_overviewData.isEmpty) {
      // Ambil flag dari backend (Default false jika null)
      bool hasTransactions = _tripData['has_transactions'] ?? false;

      if (hasTransactions) {
        // KONDISI A: Ada transaksi, tapi overview kosong = LUNAS! 🎉
        return _buildAllSettledState();
      } else {
        // KONDISI B: Belum ada transaksi sama sekali
        return _buildEmptyState("No expenses added yet.");
      }
    }

    // 2. Jika ada data Overview (Normal), tampilkan list
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_overviewData.length, (index) {
          final member = _overviewData[index];
          final amount = double.tryParse(member['amount'].toString()) ?? 0.0;
          final isPositive = amount >= 0;
          final isLast = index == _overviewData.length - 1;
          final name = member['name'] ?? 'Unknown';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPositive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          name +
                              (member['is_current_user'] == true
                                  ? ' (You)'
                                  : ''),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Menampilkan Amount dengan format mata uang
                    Text(
                      (isPositive ? '+ ' : '- ') +
                          _formatCurrency(amount.abs()),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border.withOpacity(0.3),
                  indent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  // 👇 Widget Baru untuk Tampilan "Lunas"
  Widget _buildAllSettledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 50,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "All Settled Up!",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No one owes anything right now.",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ✅ UI SETTLEMENT (Horizontal List + BIG AMOUNT)
  Widget _buildSettlementList() {
    if (_settlementTransactions.isEmpty) {
      return _buildEmptyState("All settled up!");
    }

    return Column(
      children: List.generate(_settlementTransactions.length, (index) {
        final transaction = _settlementTransactions[index];
        final fromName = transaction['from_name'] ?? 'Unknown';
        final toName = transaction['to_name'] ?? 'Unknown';
        final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
        final status = transaction['status'];
        final isPaid =
            status == 'paid'; // Sesuaikan status backend ('paid'/'confirmed')

        // ✅ PERBAIKAN 1: Samakan nama variabel jadi 'isMyObligation'
        final bool isMyObligation =
            _currentMemberId != null &&
            transaction['from_member_id'] == _currentMemberId;

        final bool isAdmin =
            widget.currentUserId != null &&
            widget.currentUserId == widget.tripOwnerId;

        // Logic tombol muncul
        final bool canMarkPaid = isMyObligation || isAdmin;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: (isMyObligation && !isPaid)
                ? Border.all(color: Colors.red.withOpacity(0.1), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSmallAvatar(fromName, Colors.red),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isMyObligation ? 'You' : fromName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isMyObligation
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isMyObligation ? Colors.red : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                        _buildSmallAvatar(toName, Colors.green),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            toName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isPaid
                            ? Colors.grey[400]
                            : AppColors.textPrimary,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildStatusWidget(isPaid, canMarkPaid, transaction),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusWidget(
    bool isPaid,
    bool isMyObligation,
    Map<String, dynamic> transaction,
  ) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Paid',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    } else if (isMyObligation) {
      return ElevatedButton(
        onPressed: () => _payDebt(transaction),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.trivaBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Set as Paid',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.trivaYellow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Not paid yet',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.trivaYellow,
          ),
        ),
      );
    }
  }

  Widget _buildSmallAvatar(String name, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
