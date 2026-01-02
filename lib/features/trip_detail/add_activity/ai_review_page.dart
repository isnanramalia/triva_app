import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahkan ini untuk input formatter
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
    // ============================================
    // 1. LOAD HEADER (MERCHANT, TAX, SERVICE)
    // ============================================

    // Title / Merchant
    if (widget.aiResult.containsKey('title')) {
      _titleController.text = widget.aiResult['title'].toString();
    } else if (widget.aiResult.containsKey('merchant')) {
      _titleController.text = widget.aiResult['merchant'].toString();
    }

    // Tax
    if (widget.aiResult.containsKey('tax')) {
      _taxController.text = widget.aiResult['tax'].toString().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
    }

    // Service Charge
    if (widget.aiResult.containsKey('service_charge')) {
      _serviceController.text = widget.aiResult['service_charge']
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
    }

    // ============================================
    // 2. LOAD ITEMS & HITUNG UNIT PRICE
    // ============================================
    final rawItems = widget.aiResult['items'] as List? ?? [];
    final members = widget.members;

    for (var item in rawItems) {
      String name = item['name'] ?? '';

      // --- PERBAIKAN QTY (INTEGER ONLY) ---
      // 1. Ambil sebagai double dulu (untuk handle string "1.0")
      double rawQty = double.tryParse(item['qty'].toString()) ?? 1.0;
      // 2. Konversi paksa ke Integer
      int qty = rawQty.toInt();
      if (qty == 0) qty = 1;

      // --- LOGIKA UNIT PRICE ---
      double? explicitUnitPrice = double.tryParse(
        item['unit_price'].toString(),
      );
      if (explicitUnitPrice == null) {
        explicitUnitPrice = double.tryParse(item['price'].toString());
      }

      double finalUnitPrice = 0.0;
      if (explicitUnitPrice != null) {
        finalUnitPrice = explicitUnitPrice;
      } else {
        // Hitung manual: Total / Qty
        double totalItem = double.tryParse(item['total'].toString()) ?? 0.0;
        if (totalItem > 0) {
          finalUnitPrice = totalItem / qty;
        }
      }

      // ============================================
      // 3. LOAD ASSIGNMENTS (SPLIT MEMBERS)
      // ============================================
      List<Map<String, dynamic>> matchedAssignments = [];
      var splitDataRaw = item['item_splits'] ?? item['assigned_to'];
      List<dynamic> rawSplits = (splitDataRaw is List) ? splitDataRaw : [];

      for (var split in rawSplits) {
        String nameToSearch = "";
        int splitQty = 1;

        if (split is String) {
          nameToSearch = split;
        } else if (split is Map) {
          nameToSearch = split['name'] ?? split['member_name'] ?? "";
          splitQty = int.tryParse(split['qty'].toString()) ?? 1;
        }

        var foundMember = members.firstWhere(
          (m) => m['name'].toString().toLowerCase().contains(
            nameToSearch.toLowerCase(),
          ),
          orElse: () => null,
        );

        if (foundMember != null) {
          matchedAssignments.add({
            'member_id': foundMember['id'],
            'qty': splitQty,
          });
        }
      }

      // Masukkan ke State UI
      _editableItems.add({
        'name_controller': TextEditingController(text: name),
        // Qty sebagai String Integer ("1")
        'qty_controller': TextEditingController(text: qty.toString()),
        'price_controller': TextEditingController(
          text: finalUnitPrice.toInt().toString(),
        ),
        'assignments': matchedAssignments,
      });
    }

    setState(() {});
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
        'assignments': initialAssignments != null
            ? List<Map<String, dynamic>>.from(initialAssignments)
            : <Map<String, dynamic>>[],
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

  // --- PERBAIKAN LOGIC SUBTOTAL (Int Qty) ---
  double get _subtotal => _editableItems.fold(0.0, (sum, item) {
    int q = int.tryParse(item['qty_controller'].text) ?? 0; // Baca sebagai int
    double p = double.tryParse(item['price_controller'].text) ?? 0.0;
    return sum + (q * p);
  });

  double get _total =>
      _subtotal +
      (double.tryParse(_taxController.text) ?? 0.0) +
      (double.tryParse(_serviceController.text) ?? 0.0);

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    if (_selectedPaidByMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Pilih siapa yang membayar (Paid By)")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (int i = 0; i < _editableItems.length; i++) {
        final item = _editableItems[i];
        final assignments = item['assignments'] as List;
        final name = item['name_controller'].text;

        if (assignments.isEmpty) {
          throw Exception(
            "Item '${name.isEmpty ? 'Baris ke-${i + 1}' : name}' belum di-assign ke member mana pun!",
          );
        }
      }

      final payload = {
        'title': _titleController.text,
        'draft_id': 'force_new_${DateTime.now().millisecondsSinceEpoch}',
        'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'paid_by_member_id': _selectedPaidByMemberId,
        'tax': double.tryParse(_taxController.text) ?? 0,
        'service_charge': double.tryParse(_serviceController.text) ?? 0,
        'tax_split_mode': 'proportional',
        'items': _editableItems.map((item) {
          // --- PERBAIKAN SAVE (Int Qty) ---
          final int q = int.tryParse(item['qty_controller'].text) ?? 1;
          final double p =
              double.tryParse(item['price_controller'].text) ?? 0.0;

          final rawAssignments =
              item['assignments'] as List<Map<String, dynamic>>;

          final splits = rawAssignments.map((a) {
            return {'member_id': a['member_id'], 'qty': a['qty']};
          }).toList();

          return {
            'name': item['name_controller'].text,
            'qty': q, // Kirim Int ke backend
            'total': q * p,
            'splits': splits,
          };
        }).toList(),
      };

      print("🚀 Sending Payload: ${payload['items']}");

      final success = await TripService().saveAiTransaction(
        widget.tripId,
        payload,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Transaksi berhasil disimpan!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Gagal menyimpan ke server");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedPaidByMemberId,
                isExpanded: true,
                hint: const Text("Pilih Pembayar"),
                items: widget.members.map((m) {
                  final String name =
                      m['user']?['name'] ??
                      m['name'] ??
                      m['guest_name'] ??
                      'Unknown Member';
                  final int memberId = int.tryParse(m['id'].toString()) ?? 0;

                  return DropdownMenuItem<int>(
                    value: memberId,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedPaidByMemberId = val);
                },
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 24),
                _buildPaidBySelector(),
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
                const SizedBox(height: 12),
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
        const SizedBox(height: 4),
        TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 14),
          decoration: _getInputDecoration(hintText: "E.g. Dinner at Beach"),
        ),
        const SizedBox(height: 12),
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
                        ),
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
    // --- PERBAIKAN DISPLAY QTY ---
    // Pakai int.tryParse supaya hitungan di UI visual benar
    int itemTotalQty = int.tryParse(item['qty_controller'].text) ?? 0;
    double itemPrice = double.tryParse(item['price_controller'].text) ?? 0.0;

    final assignments = item['assignments'] as List<Map<String, dynamic>>;
    int assignedQty = assignments.fold(
      0,
      (sum, s) => sum + (s['qty'] as num).toInt(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 4),
          TextField(
            controller: item['name_controller'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _getInputDecoration(hintText: "Item name..."),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Qty"),
                    const SizedBox(height: 4),
                    TextField(
                      controller: item['qty_controller'],
                      // --- PERBAIKAN INPUT QTY ---
                      // Hanya boleh angka, tidak boleh desimal
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),
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
          const SizedBox(height: 6),
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
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
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
                          ),
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
                  Container(
                    height: 36,
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
                          padding: EdgeInsets.zero,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            height: 48,
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
