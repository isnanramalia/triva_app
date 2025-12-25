import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/emoji_picker_sheet.dart';

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
  final List<Map<String, dynamic>> members;
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

  // State Emoji
  String _selectedEmoji = '🍽️';

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
    for (var member in widget.members) {
      _splitPortions[member['name']] = 1.0;
    }
    _recalculateSplit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    for (var c in _paidByControllers.values) {
      c.dispose();
    }
    for (var c in _splitControllers.values) {
      c.dispose();
    }
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
    // Note: 'custom' tidak dihitung ulang otomatis agar input user tidak tertimpa
    setState(() {});
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
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

  void _saveActivity() {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _paidByList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final totalPaidBy = _paidByList.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as double),
    );
    final totalAmount =
        double.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0.0;

    if ((totalPaidBy - totalAmount).abs() > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total paid (${_formatCurrency(totalPaidBy)}) must equal amount (${_formatCurrency(totalAmount)})',
          ),
        ),
      );
      return;
    }

    final activityData = {
      'title': _titleController.text,
      'emoji': _selectedEmoji,
      'amount': totalAmount,
      'date': DateTime.now().toString(),
      'paid_by': _paidByList,
      'split_type': _splitType,
      'split': _splitAmounts,
    };

    widget.onActivityAdded(activityData);
    Navigator.pop(context);
  }

  void _showEmojiPicker() {
    showEmojiPickerSheet(
      context,
      onSelected: (emoji) {
        setState(() => _selectedEmoji = emoji);
      },
    );
  }

  // --- Input Decoration Helper (Agar Konsisten) ---
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

      // ✅ PERBAIKAN: Pakai AppColors.border, bukan BorderSide.none
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),

      // Saat diklik warnanya biru
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: AppColors.trivaBlue),
      ),

      // Default fallback
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
            onPressed: _tabController.index == 0 ? _saveActivity : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trivaBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
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
          // --- TITLE INPUT ---
          const Text(
            'Title',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Emoji Picker
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(color: AppColors.border), // ✅ ADA BORDER
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Title TextField
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

          // --- AMOUNT INPUT ---
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
              GestureDetector(
                onTap: () {
                  final available = widget.members.firstWhere(
                    (m) => !_paidByList.any((p) => p['name'] == m['name']),
                    orElse: () => widget.members.first,
                  );
                  _addPayer(available['name']);
                },
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.trivaBlue),
                    Text(
                      ' Add',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.trivaBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_paidByList.isEmpty)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_borderRadius),
                border: Border.all(color: AppColors.border), // ✅ ADA BORDER
              ),
              alignment: Alignment.center,
              child: Text(
                'Who paid?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
            )
          else
            ...List.generate(_paidByList.length, (index) {
              return _buildPaidByRow(index);
            }),

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

  // --- Widgets for Lists ---

  Widget _buildPaidByRow(int index) {
    final payer = _paidByList[index];
    final name = payer['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // 1. Name Dropdown (Dibuat mirip TextField)
          Expanded(
            flex: 4,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_borderRadius),
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

          const SizedBox(width: 8),

          // 2. Amount Input (TextField Murni)
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paidByControllers[name],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 15),
                    onChanged: (value) {
                      final amount =
                          double.tryParse(
                            value.replaceAll('.', '').replaceAll(',', ''),
                          ) ??
                          0.0;
                      _updatePayerAmount(name, amount);
                    },
                    decoration: _getInputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _removePayer(index),
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[400]),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      // Custom Split
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
                    // Override border untuk custom input di dalam list agar lebih tipis/berbeda jika mau
                    // Tapi disini saya pakai style standard agar konsisten
                    filled: true,
                    fillColor: AppColors
                        .surface, // Sedikit berbeda biar kelihatan input
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
