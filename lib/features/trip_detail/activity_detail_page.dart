import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class ActivityDetailPage extends StatefulWidget {
  final int activityId;
  final Map<String, dynamic> activityData;

  const ActivityDetailPage({
    super.key,
    required this.activityId,
    required this.activityData,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late Map<String, dynamic> _activityDetail;

  @override
  void initState() {
    super.initState();
    // Mock data
    _activityDetail = {
      "id": widget.activityId,
      "title": widget.activityData['title'] ?? 'Activity',
      "emoji": widget.activityData['emoji'] ?? '📝',
      "created_by": "Ahmad",
      "category": "Accommodation",
      "total_amount": 13000000,
      "paid_by": [
        {"name": "Ahmad", "amount": 7000000},
        {"name": "Budi", "amount": 6000000},
      ],
      "settlement": [
        {"name": "Neena", "amount": -2600000},
        {"name": "Ahmad", "amount": 4400000},
        {"name": "Budi", "amount": 3400000},
        {"name": "Amanda", "amount": -2600000},
        {"name": "Risa", "amount": -2600000},
      ],
    };
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount.abs()); // .abs() agar minus tidak double di UI
  }

  // --- WIDGET BUILDER HELPERS ---

  // Helper untuk membuat Row info (Nama --- Harga)
  Widget _buildListRow({
    required String title,
    required num amount,
    required bool isLastItem,
    bool showSign = false, // Untuk menampilkan + atau -
  }) {
    final isPositive = amount >= 0;
    final color = showSign
        ? (isPositive ? Colors.green : Colors.red)
        : AppColors.textPrimary;

    String textAmount = _formatCurrency(amount);
    if (showSign) {
      textAmount = (isPositive ? '+ ' : '- ') + textAmount;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                textAmount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (!isLastItem)
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.border.withOpacity(0.3),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }

  // Helper untuk membuat Section kotak putih (Paid By & Settlement)
  Widget _buildSection({
    required String title,
    required List<dynamic> items,
    required bool isSettlement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // Opsional: Tambahkan border tipis agar konsisten dengan halaman lain
            // border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return _buildListRow(
                title: item['name'],
                amount: item['amount'],
                isLastItem: isLast,
                showSign: isSettlement, // Tampilkan +/- hanya jika settlement
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER (REFACTORED: NO STACK) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.trivaBlue,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    label: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Title
                  const Text(
                    'Activities',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Actions (Nav & Edit)
                  Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: AppColors.textSecondary.withOpacity(0.3),
                        size: 28,
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary.withOpacity(0.3),
                        size: 28,
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.trivaBlue,
                          minimumSize: const Size(40, 30),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Activity Icon & Title
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _activityDetail['emoji'],
                            style: const TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _activityDetail['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created by ${_activityDetail['created_by']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Category Badge & Total Amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _activityDetail['category'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.trivaBlue,
                              ),
                            ),
                          ),
                          Text(
                            _formatCurrency(_activityDetail['total_amount']),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Paid By Section (Reusable)
                    _buildSection(
                      title: 'Paid By',
                      items: _activityDetail['paid_by'],
                      isSettlement: false,
                    ),

                    const SizedBox(height: 24),

                    // 4. Settlement Section (Reusable)
                    _buildSection(
                      title: 'Settlement',
                      items: _activityDetail['settlement'],
                      isSettlement: true,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
