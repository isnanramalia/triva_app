import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  // 1. BALANCE OVERVIEW
  final List<Map<String, dynamic>> _summaryData = [
    {"name": "Neena", "amount": -1960000},
    {"name": "Ahmad", "amount": 3540000},
    {"name": "Budi", "amount": 2540000},
    {"name": "Amanda", "amount": -3460000},
    {"name": "Risa", "amount": -660000},
  ];

  // 2. SETTLEMENT TRANSACTIONS
  final List<Map<String, dynamic>> _settlementTransactions = [
    {
      "from": "You", // User login
      "to": "Ahmad",
      "amount": 3460000,
      "status": "unpaid"
    },
    {
      "from": "Neena",
      "to": "Budi",
      "amount": 1960000,
      "status": "paid"
    },
    {
      "from": "Risa",
      "to": "Budi",
      "amount": 580000,
      "status": "unpaid"
    },
    {
      "from": "Risa",
      "to": "Ahmad",
      "amount": 80000,
      "status": "unpaid"
    },
  ];

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  void _togglePaymentStatus(int index) {
    // Hanya bisa ubah status jika user yang terlibat ("You")
    if (_settlementTransactions[index]['from'] != 'You') return;

    setState(() {
      if (_settlementTransactions[index]['status'] == 'unpaid') {
        _settlementTransactions[index]['status'] = 'paid';
      } else {
        _settlementTransactions[index]['status'] = 'unpaid';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.trivaBlue),
              const Text('Back', style: TextStyle(fontSize: 17, color: AppColors.trivaBlue)),
            ],
          ),
        ),
        leadingWidth: 80,
        title: const Text(
          'Summary', 
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: BALANCE OVERVIEW ---
              const Text(
                'Balance Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(_summaryData.length, (index) {
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
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
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
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) Divider(height: 1, thickness: 0.5, color: AppColors.border.withValues(alpha: 0.3), indent: 16),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 32),

              // --- SECTION 2: SETTLEMENT ---
              const Text(
                'Settlement',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Suggested payments to settle debts.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),

              ...List.generate(_settlementTransactions.length, (index) {
                final transaction = _settlementTransactions[index];
                final from = transaction['from'];
                final to = transaction['to'];
                final amount = transaction['amount'];
                final status = transaction['status'];
                
                final isPaid = status == 'paid';
                final isMyObligation = from == 'You'; 
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    // Highlight border if I need to pay
                    border: isMyObligation && !isPaid ? Border.all(color: AppColors.trivaBlue.withValues(alpha: 0.3), width: 1) : null,
                  ),
                  child: Row(
                    children: [
                      // Kiri: Detail Transaksi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildSmallAvatar(from, Colors.red),
                                const SizedBox(width: 8),
                                Text(from, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                                ),
                                _buildSmallAvatar(to, Colors.green),
                                const SizedBox(width: 8),
                                Text(to, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                _formatCurrency(amount),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Kanan: Action Button / Status Label
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _buildStatusWidget(isPaid, isMyObligation, index),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Logika Status/Button
  // Widget Logika Status/Button
  Widget _buildStatusWidget(bool isPaid, bool isMyObligation, int index) {
    if (isPaid) {
      // Status LUNAS (Paid)
      // Menggunakan ButtonStyle agar tetap Hijau meskipun disabled (onPressed: null)
      return OutlinedButton(
        onPressed: isMyObligation ? () => _togglePaymentStatus(index) : null,
        style: ButtonStyle(
          // Paksa warna text jadi Hijau di semua kondisi (termasuk disabled)
          foregroundColor: WidgetStateProperty.all(Colors.green),
          // Paksa border jadi Hijau di semua kondisi
          side: WidgetStateProperty.all(const BorderSide(color: Colors.green)),
          // Styling lainnya
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
          minimumSize: WidgetStateProperty.all(const Size(0, 32)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        child: const Text('Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
    } else if (isMyObligation) {
      // Belum Bayar & Hutang Saya -> Tombol Biru Aktif
      return ElevatedButton(
        onPressed: () => _togglePaymentStatus(index),
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
      );
    } else {
      // Belum Bayar & Hutang Orang Lain -> Label Teks
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Not paid yet',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
        ),
      );
    }
  }

  Widget _buildSmallAvatar(String name, Color color) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Center(child: Text(name[0], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
    );
  }
}