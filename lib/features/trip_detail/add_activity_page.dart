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

class _AddActivityPageState extends State<AddActivityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  
  // State Emoji (String biasa karena bukan input keyboard)
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
  final double _fieldHeight = 44.0;
  final double _borderRadius = 10.0;
  
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
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    
    if (_splitType == 'equally') {
      final perPerson = widget.members.isNotEmpty ? amount / widget.members.length : 0.0;
      _splitAmounts = {};
      for (var member in widget.members) {
        _splitAmounts[member['name']] = perPerson;
      }
    } else if (_splitType == 'portion') {
      final totalPortions = _splitPortions.values.fold(0.0, (sum, portion) => sum + portion);
      _splitAmounts = {};
      for (var member in widget.members) {
        final portion = _splitPortions[member['name']] ?? 1.0;
        _splitAmounts[member['name']] = totalPortions > 0 ? (amount * portion / totalPortions) : 0.0;
      }
    }
    setState(() {});
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
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
    if (_paidByList.any((p) => p['name'] == newName && _paidByList.indexOf(p) != index)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member already added')));
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
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _paidByList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final totalPaidBy = _paidByList.fold<double>(0.0, (sum, item) => sum + (item['amount'] as double));
    final totalAmount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    
    if ((totalPaidBy - totalAmount).abs() > 100) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Total paid (${_formatCurrency(totalPaidBy)}) must equal amount (${_formatCurrency(totalAmount)})')));
      return;
    }

    final activityData = {
      'title': _titleController.text, 'emoji': _selectedEmoji, 'amount': totalAmount, 'date': DateTime.now().toString(),
      'paid_by': _paidByList, 'split_type': _splitType, 'split': _splitAmounts,
    };

    widget.onActivityAdded(activityData);
    Navigator.pop(context);
  }

  void _showEmojiPicker() {
  showEmojiPickerSheet(
    context, 
    onSelected: (emoji) {
      setState(() => _selectedEmoji = emoji);
    }
  );
}
  // --- UI Components ---

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
          child: Text('Cancel', style: TextStyle(fontSize: 17, color: AppColors.trivaBlue, fontWeight: FontWeight.w400)),
        ),
        title: const Text('Add Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 40,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(2),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]),
              labelColor: Colors.black, unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent, indicatorSize: TabBarIndicatorSize.tab,
              onTap: (index) => setState(() {}),
              tabs: const [Tab(text: 'Manual'), Tab(text: 'Smart Add ✨')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildManualTab(),
                _buildSmartAddTab(),
              ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Add', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
          const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Emoji Picker (Statis - Fixed Size)
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56, 
                  height: _fieldHeight,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
                  alignment: Alignment.center, // Pastikan emoji di tengah
                  child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 8),
              
              // Title Text Field
              Expanded(
                child: Container(
                  height: _fieldHeight,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 17),
                    // Hapus alignment container dan gunakan contentPadding + isDense
                    decoration: InputDecoration(
                      hintText: 'E.g. Villa',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      isDense: true,
                      // Jarak vertikal agar teks pas di tengah container 44px
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- AMOUNT INPUT ---
          const Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: _fieldHeight,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(_borderRadius)
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
              onChanged: (value) => _recalculateSplit(),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: const Text('Rp', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppColors.textPrimary)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- PAID BY SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paid By', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () {
                   final available = widget.members.firstWhere(
                     (m) => !_paidByList.any((p) => p['name'] == m['name']), 
                     orElse: () => widget.members.first
                   );
                   _addPayer(available['name']);
                },
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.trivaBlue),
                    Text(' Add', style: TextStyle(fontSize: 13, color: AppColors.trivaBlue, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_paidByList.isEmpty)
             Container(
               height: _fieldHeight,
               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
               alignment: Alignment.center,
               child: Text('Who paid?', style: TextStyle(fontSize: 15, color: AppColors.textSecondary.withValues(alpha: 0.5))),
             )
          else
            ...List.generate(_paidByList.length, (index) {
              final payer = _paidByList[index];
              final name = payer['name'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    // --- SELECT NAME (Dropdown) ---
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: _fieldHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(_borderRadius)
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: name,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'SF_Pro_Font'),
                            items: widget.members.map((m) => DropdownMenuItem(value: m['name'] as String, child: Text(m['name']))).toList(),
                            onChanged: (val) => val != null ? _changePayerName(index, val) : null,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // --- INPUT AMOUNT + X BUTTON ---
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          // Input Amount (Dalam Container Putih)
                          Expanded(
                            child: Container(
                              height: _fieldHeight,
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(_borderRadius)
                              ),
                              child: TextField(
                                controller: _paidByControllers[name],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 15),
                                onChanged: (value) {
                                  final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
                                  _updatePayerAmount(name, amount);
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 8),
                                    child: Text('Rp', style: TextStyle(fontSize: 15, color: AppColors.textSecondary.withValues(alpha: 0.6))),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 4), // Gap
                          
                          // Tombol X (Tanpa Background)
                          IconButton(
                            onPressed: () => _removePayer(index),
                            icon: Icon(Icons.close, size: 20, color: Colors.grey[400]),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // --- SPLIT SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Split', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.trivaBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _splitType,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.trivaBlue),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.trivaBlue, fontFamily: 'SF_Pro_Font'),
                    isDense: true,
                    items: const [
                       DropdownMenuItem(value: 'equally', child: Text('Equally')),
                       DropdownMenuItem(value: 'portion', child: Text('By Portion')),
                       DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                         setState(() {
                            _splitType = val;
                            if (val == 'custom') {
                              for (var member in widget.members) {
                                if (!_splitControllers.containsKey(member['name'])) {
                                  _splitControllers[member['name']] = TextEditingController(
                                    text: NumberFormat('#,###', 'id_ID').format(_splitAmounts[member['name']] ?? 0)
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
            child: Column(
              children: List.generate(widget.members.length, (index) {
                final member = widget.members[index];
                final name = member['name'];
                final amount = _splitAmounts[name] ?? 0.0;
                final isLast = index == widget.members.length - 1;
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: _buildSplitRow(name, amount),
                    ),
                    if (!isLast) Divider(height: 1, thickness: 0.5, color: AppColors.border.withValues(alpha: 0.3), indent: 16, endIndent: 16),
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

  Widget _buildSplitRow(String name, double amount) {
    if (_splitType == 'equally') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(_formatCurrency(amount), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              _PortionButton(icon: Icons.remove, onTap: () {
                 setState(() {
                    _splitPortions[name] = (_splitPortions[name] ?? 1.0) - 1.0;
                    if (_splitPortions[name]! < 0) _splitPortions[name] = 0;
                    _recalculateSplit();
                  });
              }),
              Container(
                width: 32, alignment: Alignment.center,
                child: Text('${(_splitPortions[name] ?? 1.0).toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              _PortionButton(icon: Icons.add, onTap: () {
                 setState(() {
                    _splitPortions[name] = (_splitPortions[name] ?? 1.0) + 1.0;
                    _recalculateSplit();
                  });
              }),
            ],
          ),
        ],
      );
    } else {
      // Custom Split Input
       return Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          Container(
            width: 100, height: 36,
            decoration: BoxDecoration(border: Border.all(color: AppColors.border.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _splitControllers[name],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none, 
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                isDense: true
              ),
              onChanged: (value) {
                final val = double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
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
          const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56, height: _fieldHeight,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
                  child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: _fieldHeight,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: 'E.g. Villa',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_borderRadius)),
            child: TextField(
              controller: _detailsController,
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Describe your expense...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3), fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9C27B0),
              side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.receipt_long, size: 20),
                SizedBox(width: 8),
                Text('Scan Receipt (optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.trivaBlue.withValues(alpha: 0.5), size: 32),
                const SizedBox(height: 8),
                Text(
                  'AI Features Coming Soon! 🚀',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.trivaBlue.withValues(alpha: 0.8)),
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
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }
}