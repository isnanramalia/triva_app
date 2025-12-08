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
    
    // Mock data lengkap untuk activity detail
    _activityDetail = {
      "id": widget.activityId,
      "title": widget.activityData['title'],
      "emoji": widget.activityData['emoji'],
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
                  // Back button with Details text
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
                          'Details',
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
                      'Activities',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Navigation arrows and Edit
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous button (disabled for now)
                      IconButton(
                        onPressed: null, // TODO: Implement navigation
                        icon: Icon(
                          Icons.chevron_left,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      // Next button (disabled for now)
                      IconButton(
                        onPressed: null, // TODO: Implement navigation
                        icon: Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      // Edit button
                      TextButton(
                        onPressed: () {
                          // TODO: Edit activity
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 30),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.trivaBlue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Icon & Title
                    Center(
                      child: Column(
                        children: [
                          // Emoji (no background)
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(
                              child: Text(
                                _activityDetail['emoji'],
                                style: const TextStyle(fontSize: 60),
                              ),
                            ),
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
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Badge & Total Amount
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _activityDetail['category'],
                              style: TextStyle(
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

                    // Paid By Section
                    const Text(
                      'Paid By',
                      style: TextStyle(
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
                      ),
                      child: Column(
                        children: List.generate(
                          _activityDetail['paid_by'].length,
                          (index) {
                            final payer = _activityDetail['paid_by'][index];
                            final isLast = index == _activityDetail['paid_by'].length - 1;
                            
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        payer['name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(payer['amount']),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: AppColors.border.withValues(alpha: 0.3),
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Settlement Section
                    const Text(
                      'Settlement',
                      style: TextStyle(
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
                      ),
                      child: Column(
                        children: List.generate(
                          _activityDetail['settlement'].length,
                          (index) {
                            final member = _activityDetail['settlement'][index];
                            final amount = member['amount'] as int;
                            final isPositive = amount >= 0;
                            final isLast = index == _activityDetail['settlement'].length - 1;
                            
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        member['name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        (isPositive ? '+ ' : '- ') + _formatCurrency(amount.abs()),
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
                                    color: AppColors.border.withValues(alpha: 0.3),
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
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