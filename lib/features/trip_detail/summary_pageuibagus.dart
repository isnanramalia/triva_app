import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';

class SummaryPage extends StatefulWidget {
  final int tripId;

  const SummaryPage({super.key, required this.tripId});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isLoading = true;
  int? _currentMemberId;

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
    try {
      final fromId = transaction['from_member_id'];
      final toId = transaction['to_member_id'];
      final rawAmount = transaction['amount'].toString().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final amount = double.tryParse(rawAmount) ?? 0.0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // ❌ Hapus AppBar standar, kita ganti custom header di body
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 1. CUSTOM HEADER (Konsisten dengan Trip Detail)
            _buildHeader(context),

            // ✅ 2. CONTENT SCROLLABLE
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
                          // --- SECTION: OVERVIEW ---
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

                          // --- SECTION: SETTLEMENT ---
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

  // ✅ WIDGET HEADER BARU (Sama persis dengan Detail Trip)
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
                      'Details', // Kembali ke halaman Details
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
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewList() {
    if (_overviewData.isEmpty) return _buildEmptyState("No balance data yet.");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (isPositive ? '+ ' : '- ') + _formatCurrency(amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
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

  // ✅ UI SETTLEMENT BARU (Bridge Layout)
  Widget _buildSettlementList() {
    if (_settlementTransactions.isEmpty)
      return _buildEmptyState("All settled up!");

    return Column(
      children: List.generate(_settlementTransactions.length, (index) {
        final transaction = _settlementTransactions[index];
        final fromName = transaction['from_name'] ?? 'Unknown';
        final toName = transaction['to_name'] ?? 'Unknown';
        final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
        final status = transaction['status'];

        final isPaid = status == 'paid';
        final isMyObligation =
            _currentMemberId != null &&
            transaction['from_member_id'] == _currentMemberId;
        final isReceiving =
            _currentMemberId != null &&
            transaction['to_member_id'] == _currentMemberId;

        // Visual Style: Kalau ini urusan saya (bayar/terima), buat lebih terang. Kalau urusan orang lain, agak redup.
        final double opacity = (isMyObligation || isReceiving) ? 1.0 : 0.6;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity == 1.0 ? 1 : 0.9),
            borderRadius: BorderRadius.circular(16),
            // Border merah tipis kalau saya harus bayar dan belum lunas
            border: (isMyObligation && !isPaid)
                ? Border.all(color: Colors.red.withOpacity(0.2), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row 1: Flow Visual (Avatar A -> Amount -> Avatar B)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SENDER (KIRI)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildMediumAvatar(fromName, Colors.red, isPaid),
                        const SizedBox(height: 8),
                        Text(
                          isMyObligation ? 'You' : fromName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Sender',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CONNECTION (TENGAH)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Text(
                          _formatCurrency(amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isPaid ? Colors.grey : AppColors.textPrimary,
                            decoration: isPaid
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  isPaid
                                      ? Icons.check_circle
                                      : Icons.arrow_forward,
                                  size: 16,
                                  color: isPaid
                                      ? Colors.green
                                      : Colors.grey[400],
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RECEIVER (KANAN)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildMediumAvatar(toName, Colors.green, isPaid),
                        const SizedBox(height: 8),
                        Text(
                          isReceiving ? 'You' : toName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Receiver',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Row 2: Action Button (Jika belum lunas)
              if (!isPaid) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isMyObligation
                      ? ElevatedButton(
                          onPressed: () => _payDebt(transaction),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.trivaBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Mark as Paid',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Waiting for payment',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // Helper Avatar agak besar untuk Settlement Card
  Widget _buildMediumAvatar(String name, Color color, bool isDimmed) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDimmed ? Colors.grey[200] : color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDimmed ? Colors.grey : color,
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
