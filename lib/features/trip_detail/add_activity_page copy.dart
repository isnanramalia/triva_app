import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/emoji_picker_sheet.dart';
import '../../../core/services/trip_service.dart'; // ✅ Import Service

// Helper Navigation (Full Page)
void navigateToAddActivityPage(
  BuildContext context, {
  required int tripId,
  required List<Map<String, dynamic>> members,
  required Function(Map<String, dynamic>) onActivityAdded,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => AddActivityPage(
        tripId: tripId,
        members: members,
        onActivityAdded: onActivityAdded,
      ),
    ),
  );
}

class AddActivityPage extends StatefulWidget {
  final int tripId;
  final List<Map<String, dynamic>>
  members; // Isinya: [{'id': 1, 'name': 'Budi'}, ...]
  final Function(Map<String, dynamic>) onActivityAdded;

  const AddActivityPage({
    super.key,
    required this.tripId,
    required this.members,
    required this.onActivityAdded,
  });

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();

  // State
  String _selectedEmoji = '🍽️';
  bool _isSubmitting = false; // Loading state saat simpan

  // Paid By Data
  final List<Map<String, dynamic>> _paidByList = [];
  final Map<String, TextEditingController> _paidByControllers = {};

  // Split Data
  String _splitType = 'equally';
  final Map<String, double> _splitPortions = {};
  Map<String, double> _splitAmounts = {};
  final Map<String, TextEditingController> _splitControllers = {};

  // Style Constants
  final double _borderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Init Split Portions
    for (var member in widget.members) {
      _splitPortions[member['name']] = 1.0;
    }

    // Default Payer: Orang pertama di list (biasanya User yang login/admin)
    if (widget.members.isNotEmpty) {
      _addPayer(widget.members.first['name']);
    }

    _recalculateSplit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    for (var c in _paidByControllers.values) c.dispose();
    for (var c in _splitControllers.values) c.dispose();
    super.dispose();
  }

  // --- Logic Calculations ---

  void _recalculateSplit() {
    final amount =
        double.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0.0;

    if (_splitType == 'equally') {
      final perPerson = widget.members.isNotEmpty
          ? amount / widget.members.length
          : 0.0;
      _splitAmounts = {};
      for (var member in widget.members) {
        _splitAmounts[member['name']] = perPerson;
      }
    } else if (_splitType == 'portion') {
      final totalPortions = _splitPortions.values.fold(
        0.0,
        (sum, portion) => sum + portion,
      );
      _splitAmounts = {};
      for (var member in widget.members) {
        final portion = _splitPortions[member['name']] ?? 1.0;
        _splitAmounts[member['name']] = totalPortions > 0
            ? (amount * portion / totalPortions)
            : 0.0;
      }
    }
    setState(() {});
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _addPayer(String name) {
    if (!_paidByList.any((p) => p['name'] == name)) {
      setState(() {
        _paidByList.add({'name': name, 'amount': 0.0});
        _paidByControllers[name] = TextEditingController(text: '0');
      });
    }
  }

  void _changePayerName(int index, String newName) {
    if (_paidByList.any(
      (p) => p['name'] == newName && _paidByList.indexOf(p) != index,
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member already added')));
      return;
    }
    setState(() {
      final oldName = _paidByList[index]['name'];
      _paidByList[index]['name'] = newName;
      final controller = _paidByControllers[oldName];
      _paidByControllers.remove(oldName);
      if (controller != null) _paidByControllers[newName] = controller;
    });
  }

  void _removePayer(int index) {
    setState(() {
      final name = _paidByList[index]['name'];
      _paidByList.removeAt(index);
      _paidByControllers[name]?.dispose();
      _paidByControllers.remove(name);
    });
  }

  void _updatePayerAmount(String name, double amount) {
    final index = _paidByList.indexWhere((p) => p['name'] == name);
    if (index != -1) {
      setState(() => _paidByList[index]['amount'] = amount);
    }
  }

  void _updateCustomSplitAmount(String name, double amount) {
    setState(() => _splitAmounts[name] = amount);
  }

  // ✅ LOGIC SIMPAN KE API
  Future<void> _saveActivity() async {
    // 1. Validasi Input Basic
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _paidByList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final totalAmount =
        double.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0.0;

    // 2. Validasi Payer (Untuk MVP, Backend hanya support 1 payer per transaksi)
    // Jika user memasukkan multiple payer, kita ambil payer dengan jumlah terbesar atau pertama.
    // TODO: Update backend untuk support multi-payer transaction di masa depan.

    // Untuk sekarang, kita ambil payer pertama saja sebagai 'paid_by_member_id'
    final mainPayerName = _paidByList.first['name'];

    // Cari ID dari Nama Payer
    final mainPayerId = widget.members.firstWhere(
      (m) => m['name'] == mainPayerName,
      orElse: () => {'id': 0},
    )['id'];

    if (mainPayerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Payer not found in member list')),
      );
      return;
    }

    // 3. Susun Data Splits
    List<Map<String, dynamic>> splitsPayload = [];
    double totalSplitCheck = 0.0;

    _splitAmounts.forEach((name, amount) {
      if (amount > 0) {
        final memberId = widget.members.firstWhere(
          (m) => m['name'] == name,
        )['id'];
        splitsPayload.add({'member_id': memberId, 'amount': amount});
        totalSplitCheck += amount;
      }
    });

    // Validasi Total Split harus sama dengan Total Amount (Toleransi 100 rupiah utk pembulatan)
    if ((totalSplitCheck - totalAmount).abs() > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total splits must equal total amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 4. Susun Payload Akhir
    final apiPayload = {
      'title': _titleController.text,
      'description': _detailsController.text,
      'emoji': _selectedEmoji,
      'date': DateTime.now().toIso8601String(),
      'total_amount': totalAmount,
      'paid_by_member_id': mainPayerId, // Backend perlu ID
      'split_type': _splitType, // 'equally', 'portion', 'custom'
      'splits': splitsPayload,
    };

    // 5. Panggil Service
    final success = await TripService().createTransaction(
      widget.tripId,
      apiPayload,
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (success) {
      // Callback untuk update UI (Opsional, krn TripDetail akan refresh sendiri)
      widget.onActivityAdded({
        'title': _titleController.text,
        'emoji': _selectedEmoji,
        'amount': totalAmount,
        'date': DateTime.now().toIso8601String(),
        'paid_by': [
          {'name': mainPayerName},
        ], // Mock return utk UI instan
      });
      Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add activity. Check connection.'),
          ),
        );
      }
    }
  }

  void _showEmojiPicker() {
    showEmojiPickerSheet(
      context,
      onSelected: (emoji) {
        setState(() => _selectedEmoji = emoji);
      },
    );
  }

  InputDecoration _getInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.trivaBlue),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: AppColors.trivaBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        title: const Text(
          'Add Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(2),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              onTap: (index) => setState(() {}),
              tabs: const [
                Tab(text: 'Manual'),
                Tab(text: 'Smart Add ✨'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildManualTab(), _buildSmartAddTab()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: (_tabController.index == 0 && !_isSubmitting)
                ? _saveActivity
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trivaBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Add',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 17),
                  decoration: _getInputDecoration(hintText: 'E.g. Villa'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Amount',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
            onChanged: (value) => _recalculateSplit(),
            decoration: _getInputDecoration(
              hintText: '0',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 12),
                child: Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- PAID BY SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paid By',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              // NOTE: Fitur multi-payer di-hide dulu untuk MVP API
              // GestureDetector(...)
            ],
          ),
          const SizedBox(height: 8),

          // Logic Payer Sederhana (Hanya 1 Payer untuk MVP)
          if (_paidByList.isNotEmpty)
            _buildPaidByRow(0) // Hanya tampilkan index 0
          else
            const SizedBox(), // Should not happen karena initstate nambah default

          const SizedBox(height: 24),

          // --- SPLIT SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Split',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.trivaBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _splitType,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.trivaBlue,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.trivaBlue,
                      fontFamily: 'SF_Pro_Font',
                    ),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'equally',
                        child: Text('Equally'),
                      ),
                      DropdownMenuItem(
                        value: 'portion',
                        child: Text('By Portion'),
                      ),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _splitType = val;
                          if (val == 'custom') {
                            for (var member in widget.members) {
                              if (!_splitControllers.containsKey(
                                member['name'],
                              )) {
                                _splitControllers[member['name']] =
                                    TextEditingController(
                                      text: NumberFormat('#,###', 'id_ID')
                                          .format(
                                            _splitAmounts[member['name']] ?? 0,
                                          ),
                                    );
                              }
                            }
                          }
                          _recalculateSplit();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            child: Column(
              children: List.generate(widget.members.length, (index) {
                final member = widget.members[index];
                final name = member['name'];
                final amount = _splitAmounts[name] ?? 0.0;
                final isLast = index == widget.members.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: _buildSplitRow(name, amount),
                    ),
                    if (!isLast)
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
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildPaidByRow(int index) {
    final payer = _paidByList[index];
    final name = payer['name'];

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: name,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'SF_Pro_Font',
                ),
                items: widget.members
                    .map(
                      (m) => DropdownMenuItem(
                        value: m['name'] as String,
                        child: Text(m['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    val != null ? _changePayerName(index, val) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitRow(String name, double amount) {
    if (_splitType == 'equally') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Text(_formatCurrency(amount), style: const TextStyle(fontSize: 15)),
        ],
      );
    } else if (_splitType == 'portion') {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatCurrency(amount),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _PortionButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    _splitPortions[name] = (_splitPortions[name] ?? 1.0) - 1.0;
                    if (_splitPortions[name]! < 0) _splitPortions[name] = 0;
                    _recalculateSplit();
                  });
                },
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '${(_splitPortions[name] ?? 1.0).toInt()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _PortionButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    _splitPortions[name] = (_splitPortions[name] ?? 1.0) + 1.0;
                    _recalculateSplit();
                  });
                },
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _splitControllers[name],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration:
                  _getInputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ).copyWith(
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.border.withOpacity(0.3),
                      ),
                    ),
                  ),
              onChanged: (value) {
                final val =
                    double.tryParse(
                      value.replaceAll('.', '').replaceAll(',', ''),
                    ) ??
                    0.0;
                _updateCustomSplitAmount(name, val);
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSmartAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Emoji Picker (Fixed with Border)
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(
                      color: AppColors.border,
                    ), // ✅ Tambahkan ini
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Title Input
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 17),
                  // Ini sudah aman karena _getInputDecoration sudah kita perbaiki sebelumnya
                  decoration: _getInputDecoration(hintText: 'E.g. Villa'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Details',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Details Input
          TextField(
            controller: _detailsController,
            maxLines: 4,
            style: const TextStyle(fontSize: 15),
            decoration: _getInputDecoration(
              hintText: 'Describe your expense...',
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 24),

          // Scan Receipt Button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9C27B0),
              side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 20),
                SizedBox(width: 8),
                Text(
                  'Scan Receipt (optional)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // AI Placeholder
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.trivaBlue.withOpacity(0.5),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'AI Features Coming Soon! 🚀',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.trivaBlue.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PortionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PortionButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }
}
