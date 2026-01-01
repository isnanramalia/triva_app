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
  final ScrollController _scrollController = ScrollController();

  final _titleController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _serviceController = TextEditingController(text: '0');

  // Struktur data utama
  List<Map<String, dynamic>> _editableItems = [];
  bool _isSaving = false;
  int? _selectedPaidByMemberId;

  // Style Constants
  final double _borderRadius = 12.0;
  final currencyFormat = NumberFormat.currency(
    symbol: 'Rp',
    decimalDigits: 0,
    locale: 'id_ID',
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Set default ke member pertama jika tersedia
    if (widget.members.isNotEmpty) {
      _selectedPaidByMemberId = widget.members.first['id'];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final data = widget.aiResult;
    _titleController.text = data['merchant'] ?? data['title'] ?? 'New Activity';
    _taxController.text = (double.tryParse(data['tax']?.toString() ?? '0') ?? 0)
        .toInt()
        .toString();
    _serviceController.text =
        (double.tryParse(data['service_charge']?.toString() ?? '0') ?? 0)
            .toInt()
            .toString();

    final List<dynamic> rawItems = data['items'] is List ? data['items'] : [];

    for (var item in rawItems) {
      if (item == null) continue;

      String name = item['name']?.toString() ?? '';
      int qty = (double.tryParse(item['qty']?.toString() ?? '1') ?? 1).toInt();
      double price =
          double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;

      List<Map<String, dynamic>> parsedAssignments = [];
      if (item['item_splits'] is List) {
        for (var split in item['item_splits']) {
          int memberId = int.tryParse(split['member_id'].toString()) ?? 0;
          int splitQty = (double.tryParse(split['qty'].toString()) ?? 0)
              .toInt();

          if (memberId != 0 && splitQty > 0) {
            parsedAssignments.add({'member_id': memberId, 'qty': splitQty});
          }
        }
      }

      _addNewItem(
        name: name,
        qty: qty,
        price: price,
        initialAssignments: parsedAssignments,
        shouldScroll: false,
      );
    }
  }

  void _addNewItem({
    String name = '',
    int qty = 1,
    double price = 0,
    List<Map<String, dynamic>>? initialAssignments,
    bool shouldScroll = true,
  }) {
    setState(() {
      _editableItems.add({
        'name_controller': TextEditingController(text: name),
        'qty_controller': TextEditingController(text: qty.toString()),
        'price_controller': TextEditingController(
          text: price.toInt().toString(),
        ),
        'assignments': initialAssignments ?? <Map<String, dynamic>>[],
      });
    });

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _addAssignmentRow(int itemIndex) {
    final item = _editableItems[itemIndex];
    final assignments = item['assignments'] as List<Map<String, dynamic>>;

    final usedIds = assignments.map((a) => a['member_id']).toSet();

    Map<String, dynamic>? availableMember;
    for (var member in widget.members) {
      final m = member as Map<String, dynamic>;
      if (!usedIds.contains(m['id'])) {
        availableMember = m;
        break;
      }
    }

    if (availableMember != null) {
      setState(() {
        assignments.add({'member_id': availableMember!['id'], 'qty': 1});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All members already assigned.")),
      );
    }
  }

  double get _subtotal => _editableItems.fold(0.0, (sum, item) {
    double q = double.tryParse(item['qty_controller'].text) ?? 0.0;
    double p = double.tryParse(item['price_controller'].text) ?? 0.0;
    return sum + (q * p);
  });

  double get _total =>
      _subtotal +
      (double.tryParse(_taxController.text) ?? 0.0) +
      (double.tryParse(_serviceController.text) ?? 0.0);

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    // Validasi sederhana
    if (_selectedPaidByMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih siapa yang membayar terlebih dahulu"),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // FIX: Sesuaikan struktur payload dengan kebutuhan Backend Laravel
    final payload = {
      'title': _titleController.text,
      'draft_id':
          widget.aiResult['draft_id'] ??
          'ai_${DateTime.now().millisecondsSinceEpoch}',
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'paid_by_member_id':
          _selectedPaidByMemberId, // WAJIB: ID Member pengeluar
      'tax': double.tryParse(_taxController.text) ?? 0,
      'service_charge': double.tryParse(_serviceController.text) ?? 0,
      'items': _editableItems.map((item) {
        final q = double.tryParse(item['qty_controller'].text) ?? 1.0;
        final p = double.tryParse(item['price_controller'].text) ?? 0.0;

        // Map assignments (splits)
        final assignments = (item['assignments'] as List)
            .map(
              (a) => {
                'member_id': a['member_id'],
                'qty': a['qty'], // 0 = bagi rata, >0 = porsi spesifik
              },
            )
            .toList();

        return {
          'name': item['name_controller'].text,
          'qty': q,
          'total': q * p, // WAJIB: Backend butuh total per item
          'splits': assignments, // FIX: Gunakan key 'splits' sesuai backend
        };
      }).toList(),
    };

    try {
      final success = await TripService().saveAiTransaction(
        widget.tripId,
        payload,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaksi berhasil disimpan! ✅")),
          );
          Navigator.pop(context, true); // Kembali ke Trip Detail & refresh
        }
      } else {
        throw Exception("Gagal menyimpan ke server");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildPaidBySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.trivaBlue,
          ),
          const SizedBox(width: 12),
          const Text("Paid By:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<int>(
              value: _selectedPaidByMemberId,
              isExpanded: true,
              underline: const SizedBox(),
              items: widget.members.map((m) {
                final name = m['user']?['name'] ?? m['guest_name'] ?? 'Member';
                return DropdownMenuItem<int>(
                  value: m['id'],
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPaidByMemberId = val),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      // TAMBAHAN PENTING: Agar icon tidak maksa ukuran 48px (jadi bisa centering)
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      isDense: true,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.trivaBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 15, color: AppColors.trivaBlue),
          ),
        ),
        title: const Text(
          'Review Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ), // Padding vertical dikurangi
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 24), // Jarak antar section dikurangi
                _buildPaidBySelector(),
                // Section Header Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ITEMS LIST",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () => _addNewItem(),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle,
                              size: 14,
                              color: AppColors.trivaBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Add Item",
                              style: TextStyle(
                                color: AppColors.trivaBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Jarak ke list items dikurangi

                ..._editableItems.asMap().entries.map(
                  (e) => _buildItemCard(e.key, e.value),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Merchant / Title"),
        const SizedBox(height: 4), // Jarak dikurangi
        TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 14),
          decoration: _getInputDecoration(hintText: "E.g. Dinner at Beach"),
        ),
        const SizedBox(height: 12), // Jarak antar row dikurangi
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Tax"),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: _getInputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 10, right: 6),
                        child: Text(
                          "Rp",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ), // Height disesuaikan karena isDense
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Service Charge"),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _serviceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: _getInputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 10, right: 6),
                        child: Text(
                          "Rp",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    int itemTotalQty = int.tryParse(item['qty_controller'].text) ?? 0;
    double itemPrice = double.tryParse(item['price_controller'].text) ?? 0.0;

    final assignments = item['assignments'] as List<Map<String, dynamic>>;
    int assignedQty = assignments.fold(
      0,
      (sum, s) => sum + (s['qty'] as num).toInt(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Margin bawah diperkecil
      padding: const EdgeInsets.all(12), // Padding dalam diperkecil
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Item & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel("Item Name"),
              InkWell(
                onTap: () => setState(() => _editableItems.removeAt(index)),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4), // Jarak dikurangi
          TextField(
            controller: item['name_controller'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _getInputDecoration(hintText: "Item name..."),
          ),
          const SizedBox(height: 10), // Jarak ke Qty/Price dikurangi
          // Qty & Price Row
          Row(
            children: [
              SizedBox(
                width: 70, // Lebar diperkecil sedikit
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Qty"),
                    const SizedBox(height: 4),
                    TextField(
                      controller: item['qty_controller'],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: _getInputDecoration(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Price"),
                    const SizedBox(height: 4),
                    TextField(
                      controller: item['price_controller'],
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: _getInputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 6),
                          child: Text(
                            "Rp",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              height: 2.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10), // Jarak ke Subtotal dikurangi
          // Subtotal Read-only
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ), // Padding compact
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subtotal",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  currencyFormat.format(itemTotalQty * itemPrice),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.trivaBlue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5), // Divider lebih tipis
          const SizedBox(height: 10),

          // --- Assign Members Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Assign to Member",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (assignedQty != itemTotalQty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: assignedQty > itemTotalQty
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    assignedQty > itemTotalQty
                        ? "Over: ${assignedQty - itemTotalQty}"
                        : "Left: ${itemTotalQty - assignedQty}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: assignedQty > itemTotalQty
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6), // Jarak dikurangi
          // List Rows Member
          if (assignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                "No member assigned yet.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          ...assignments.asMap().entries.map((entry) {
            final assignData = entry.value;
            final assignIndex = entry.key;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 6,
              ), // Jarak antar row member dikurangi
              child: Row(
                children: [
                  // Dropdown Member
                  Expanded(
                    child: Container(
                      height: 36, // Height diperkecil (Compact)
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: assignData['member_id'],
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ), // Font diperkecil
                          items: widget.members.map<DropdownMenuItem<int>>((m) {
                            return DropdownMenuItem<int>(
                              value: m['id'],
                              child: Text(
                                m['name'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => assignData['member_id'] = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Stepper Qty
                  Container(
                    height: 36, // Height diperkecil
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 12),
                          padding: EdgeInsets.zero, // Remove internal padding
                          constraints: const BoxConstraints(minWidth: 28),
                          onPressed: () {
                            if (assignData['qty'] > 1)
                              setState(() => assignData['qty']--);
                          },
                        ),
                        Text(
                          "${assignData['qty']}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 12),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28),
                          onPressed: () => setState(() => assignData['qty']++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete Row
                  InkWell(
                    onTap: () =>
                        setState(() => assignments.removeAt(assignIndex)),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),

          // Button Add Assignment
          InkWell(
            onTap: () => _addAssignmentRow(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 14,
                    color: AppColors.trivaBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Assign Member",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.trivaBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24,
      ), // Padding bawah compact
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                currencyFormat.format(_total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.trivaBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48, // Tinggi tombol sedikit dikurangi dari 52
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.trivaBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Confirm & Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
