import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';

class AiReviewPage extends StatefulWidget {
  final int tripId;
  final List<dynamic> members;
  final Map<String, dynamic> aiResult;

  const AiReviewPage({
    super.key,
    required this.tripId,
    required this.members,
    required this.aiResult,
  });

  @override
  State<AiReviewPage> createState() => _AiReviewPageState();
}

class _AiReviewPageState extends State<AiReviewPage> {
  late TextEditingController _titleController;
  late List<dynamic> _items;
  bool _isSaving = false;
  double _tax = 0;
  double _service = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text:
          widget.aiResult['merchant'] ??
          widget.aiResult['title'] ??
          'Scan Result',
    );
    _items = List.from(widget.aiResult['items'] ?? []);
    _tax = (widget.aiResult['tax'] ?? 0).toDouble();
    _service = (widget.aiResult['service_charge'] ?? 0).toDouble();
  }

  double get _subtotal => _items.fold(
    0.0,
    (sum, item) => sum + (double.tryParse(item['total'].toString()) ?? 0),
  );
  double get _total => _subtotal + _tax + _service;

  Future<void> _saveTransaction() async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        "draft_id":
            widget.aiResult['draft_id'] ??
            "ai_${DateTime.now().millisecondsSinceEpoch}",
        "title": _titleController.text,
        "date": widget.aiResult['date'] ?? DateTime.now().toIso8601String(),
        "paid_by_member_id": widget.members.first['id'],
        "tax": _tax,
        "service_charge": _service,
        "items": _items.map((item) {
          return {
            "name": item['name'],
            "total": item['total'] ?? 0,
            "qty": item['qty'] ?? 1,
            "splits": (item['item_splits'] as List)
                .map(
                  (split) => {
                    "member_id": split['member_id'],
                    "qty": split['qty'],
                  },
                )
                .toList(),
          };
        }).toList(),
      };

      await TripService().saveAiTransaction(widget.tripId, payload);
      if (mounted) {
        Navigator.pop(context); // Close Review
        Navigator.pop(context); // Close Add Page
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Konfirmasi Scan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER CARD (Merchant Name)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nama Tempat / Judul",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.trivaBlue,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Nama Merchant",
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                        Divider(height: 24, color: Colors.grey[200]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Terdeteksi",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(_total),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Daftar Item",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // ITEM LIST
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final splits = item['item_splits'] as List;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id',
                                    symbol: '',
                                    decimalDigits: 0,
                                  ).format(item['total']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // SPLIT CHIPS
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: splits.map<Widget>((split) {
                                final isShared = split['qty'] == 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isShared
                                        ? AppColors.trivaBlue.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${split['member_name']} ${isShared ? '' : '(${split['qty']}x)'}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isShared
                                          ? AppColors.trivaBlue
                                          : Colors.green[700],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 100), // Spacer bottom
                ],
              ),
            ),
          ),

          // BOTTOM BUTTON
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.trivaBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Transaksi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
