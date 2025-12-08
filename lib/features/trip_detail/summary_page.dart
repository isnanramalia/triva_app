import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  // Mock data untuk summary - KONSISTEN DENGAN TRIP DETAIL
  // Perhitungan:
  // Villa (13.000.000) + Gondola (1.500.000) + Fine Dining (2.800.000) = 17.300.000
  // Per orang: 17.300.000 / 5 = 3.460.000
  
  // Paid by:
  // - Ahmad paid 7.000.000 for Villa
  // - Budi paid 6.000.000 for Villa
  // - Neena paid 1.500.000 for Gondola
  // - Risa paid 2.800.000 for Fine Dining
  
  // Balances:
  // - Ahmad: paid 7.000.000, owes 3.460.000, balance = +3.540.000
  // - Budi: paid 6.000.000, owes 3.460.000, balance = +2.540.000
  // - Neena: paid 1.500.000, owes 3.460.000, balance = -1.960.000
  // - Amanda: paid 0, owes 3.460.000, balance = -3.460.000
  // - Risa: paid 2.800.000, owes 3.460.000, balance = -660.000
  
  final List<Map<String, dynamic>> _summaryData = [
    {"name": "Neena", "amount": -1960000},
    {"name": "Ahmad", "amount": 3540000},
    {"name": "Budi", "amount": 2540000},
    {"name": "Amanda", "amount": -3460000},
    {"name": "Risa", "amount": -660000},
  ];

  // Settlement transactions - Simplified algorithm
  // Yang minus bayar ke yang plus secara optimal
  final List<Map<String, dynamic>> _settlementTransactions = [
    {"from": "Amanda", "to": "Ahmad", "amount": 3460000},
    {"from": "Neena", "to": "Budi", "amount": 1960000},
    {"from": "Risa", "to": "Budi", "amount": 580000},
    {"from": "Risa", "to": "Ahmad", "amount": 80000},
  ];

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
                  // Back button
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
                          'Back',
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
                      'Summary',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Placeholder for alignment
                  const SizedBox(width: 60),
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
                    // Summary Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.trivaBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.trivaBlue.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.trivaBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This shows who owes whom and how much to settle all expenses.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Summary List Header
                    const Text(
                      'Balance Overview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Summary List (Top section with balances)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: List.generate(
                          _summaryData.length,
                          (index) {
                            final member = _summaryData[index];
                            final amount = member['amount'] as int;
                            final isPositive = amount >= 0;
                            final isLast = index == _summaryData.length - 1;
                            
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          // Avatar circle
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isPositive 
                                                ? Colors.green.withValues(alpha: 0.1)
                                                : Colors.red.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                member['name'][0],
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
                                            member['name'],
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            (isPositive ? '+ ' : '- ') + _formatCurrency(amount.abs()),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isPositive ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isPositive ? 'Gets back' : 'Owes',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary.withValues(alpha: 0.6),
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

                    // Settlement Section Header
                    const Text(
                      'Settlement Transactions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suggested payments to settle all balances',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Settlement Transactions List
                    ...List.generate(
                      _settlementTransactions.length,
                      (index) {
                        final transaction = _settlementTransactions[index];
                        final isYouInvolved = transaction['from'] == 'You' || transaction['to'] == 'You';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isYouInvolved ? Border.all(
                              color: AppColors.trivaBlue.withValues(alpha: 0.3),
                              width: 1.5,
                            ) : null,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // From -> To
                                        Row(
                                          children: [
                                            // From avatar
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  transaction['from'][0],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              transaction['from'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(width: 8),
                                            // To avatar
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  transaction['to'][0],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              transaction['to'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Amount
                                        Text(
                                          _formatCurrency(transaction['amount']),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Set as Paid button (only if "You" is involved)
                              if (isYouInvolved) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // TODO: Set as paid
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.trivaBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Set as Paid',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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