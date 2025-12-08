import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Show Add Activity Sheet
void showAddActivitySheet(
  BuildContext context, {
  required int tripId,
  required List<Map<String, dynamic>> members,
  required Function(Map<String, dynamic>) onActivityAdded,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => AddActivitySheet(
      tripId: tripId,
      members: members,
      onActivityAdded: onActivityAdded,
    ),
  );
}

class AddActivitySheet extends StatefulWidget {
  final int tripId;
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic>) onActivityAdded;
  
  const AddActivitySheet({
    super.key,
    required this.tripId,
    required this.members,
    required this.onActivityAdded,
  });

  @override
  State<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<AddActivitySheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Manual Tab Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  String _selectedEmoji = '🍽️';
  
  // Paid By - Multiple members with amounts
  List<Map<String, dynamic>> _paidByList = [];
  Map<String, TextEditingController> _paidByControllers = {};
  
  // Split
  String _splitType = 'equally'; // equally, portion, custom
  Map<String, double> _splitPortions = {}; // For portion split
  Map<String, double> _splitAmounts = {}; // Final amounts
  Map<String, TextEditingController> _splitControllers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize split portions (all members start with 1.0)
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
    
    // Dispose all paid by controllers
    for (var controller in _paidByControllers.values) {
      controller.dispose();
    }
    
    // Dispose all split controllers
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

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
    // For custom, amounts are manually set
    
    setState(() {});
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmojiPickerSheet(
        onEmojiSelected: (emoji) {
          setState(() => _selectedEmoji = emoji);
        },
      ),
    );
  }

  void _addPayer(String name) {
    if (!_paidByList.any((p) => p['name'] == name)) {
      setState(() {
        _paidByList.add({'name': name, 'amount': 0.0});
        _paidByControllers[name] = TextEditingController(text: '0');
      });
    }
  }

  void _removePayer(String name) {
    setState(() {
      _paidByList.removeWhere((p) => p['name'] == name);
      _paidByControllers[name]?.dispose();
      _paidByControllers.remove(name);
    });
  }

  void _updatePayerAmount(String name, double amount) {
    final index = _paidByList.indexWhere((p) => p['name'] == name);
    if (index != -1) {
      setState(() {
        _paidByList[index]['amount'] = amount;
      });
    }
  }

  void _updateSplitType(String type) {
    setState(() {
      _splitType = type;
      
      // Initialize controllers for custom split if needed
      if (type == 'custom') {
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

  void _updateCustomSplitAmount(String name, double amount) {
    setState(() {
      _splitAmounts[name] = amount;
    });
  }

  void _addActivity() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _paidByList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final totalPaidBy = _paidByList.fold<double>(0.0, (sum, item) => sum + (item['amount'] as double));
    final totalAmount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    
    if (totalPaidBy != totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total paid (${_formatCurrency(totalPaidBy)}) must equal amount (${_formatCurrency(totalAmount)})')),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(fontSize: 17, color: AppColors.trivaBlue)),
                      ),
                      const Text('Add Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 70),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 44,
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Manual'),
                  Tab(text: 'Smart Add ✨'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildManualTab(),
                  _buildSmartAddTab(),
                ],
              ),
            ),

            // Add/Generate Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _tabController.index == 0 ? _addActivity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.trivaBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    _tabController.index == 0 ? 'Add' : 'Generate',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    final totalPaidBy = _paidByList.fold<double>(0.0, (sum, item) => sum + (item['amount'] as double));
    final totalAmount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Emoji
          const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
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

          // Amount
          const Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Rp', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 17),
                    onChanged: (value) => _recalculateSplit(),
                    decoration: InputDecoration(
                      hintText: '7.000.000',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Paid By Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paid By', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  // Show member selector
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _MemberSelectorSheet(
                      members: widget.members,
                      excludeNames: _paidByList.map((p) => p['name'] as String).toList(),
                      onMemberSelected: (name) {
                        _addPayer(name);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: Text(
                  '+ Add',
                  style: TextStyle(fontSize: 13, color: AppColors.trivaBlue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Paid By List (Inline)
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: _paidByList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No payers added',
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(_paidByList.length, (index) {
                      final payer = _paidByList[index];
                      final name = payer['name'];
                      final isLast = index == _paidByList.length - 1;
                      
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontSize: 15)),
                                ),
                                Container(
                                  width: 120,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8, right: 4),
                                        child: Text('Rp', style: TextStyle(fontSize: 13)),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _paidByControllers[name],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (value) {
                                            final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
                                            _updatePayerAmount(name, amount);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _removePayer(name),
                                  child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
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
                    }),
                  ),
          ),

          if (_paidByList.isNotEmpty && totalPaidBy != totalAmount) ...[
            const SizedBox(height: 8),
            Text(
              'Total paid: ${_formatCurrency(totalPaidBy)} (should be ${_formatCurrency(totalAmount)})',
              style: TextStyle(fontSize: 12, color: Colors.red.withValues(alpha: 0.8)),
            ),
          ],

          const SizedBox(height: 24),

          // Split Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Split', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSplitTypeButton('Equally ⚖️', 'equally'),
                  const SizedBox(width: 4),
                  _buildSplitTypeButton('By Portion 📊', 'portion'),
                  const SizedBox(width: 4),
                  _buildSplitTypeButton('Custom 🔧', 'custom'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Split Preview/Config (Inline)
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
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
                      child: _splitType == 'equally'
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 15)),
                                Text(_formatCurrency(amount), style: const TextStyle(fontSize: 15)),
                              ],
                            )
                          : _splitType == 'portion'
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(_formatCurrency(amount), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _splitPortions[name] = (_splitPortions[name] ?? 1.0) - 1.0;
                                              if (_splitPortions[name]! < 0) _splitPortions[name] = 0;
                                              _recalculateSplit();
                                            });
                                          },
                                          icon: const Icon(Icons.remove, size: 16),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                        Container(
                                          width: 32,
                                          alignment: Alignment.center,
                                          child: Text('${(_splitPortions[name] ?? 1.0).toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _splitPortions[name] = (_splitPortions[name] ?? 1.0) + 1.0;
                                              _recalculateSplit();
                                            });
                                          },
                                          icon: const Icon(Icons.add, size: 16),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: Text(name, style: const TextStyle(fontSize: 15))),
                                    Container(
                                      width: 100,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _splitControllers[name],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
                                          _updateCustomSplitAmount(name, amount);
                                        },
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
              }),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSplitTypeButton(String label, String type) {
    final isSelected = _splitType == type;
    return GestureDetector(
      onTap: () => _updateSplitType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.trivaBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppColors.trivaBlue : AppColors.textSecondary.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSmartAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Emoji
          const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 56,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
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

          // Details
          const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _detailsController,
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Describe your expense, I\'ll split it for you✨',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3), fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Scan Receipt Button
          OutlinedButton(
            onPressed: () {
              // TODO: Implement scan receipt
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9C27B0),
              side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

          const SizedBox(height: 16),

          // Info text
          Center(
            child: Text(
              'Coming Soon! 🚀',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.trivaBlue,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Member Selector Sheet
class _MemberSelectorSheet extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<String> excludeNames;
  final Function(String) onMemberSelected;

  const _MemberSelectorSheet({
    required this.members,
    required this.excludeNames,
    required this.onMemberSelected,
  });

  @override
  Widget build(BuildContext context) {
    final availableMembers = members.where((m) => !excludeNames.contains(m['name'])).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppColors.trivaBlue)),
                  ),
                  const Text('Select Member', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableMembers.length,
                itemBuilder: (context, index) {
                  final member = availableMembers[index];
                  return GestureDetector(
                    onTap: () => onMemberSelected(member['name']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        member['name'],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Emoji Picker Sheet
class _EmojiPickerSheet extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const _EmojiPickerSheet({required this.onEmojiSelected});

  static const List<String> _emojis = [
    '🍽️', '🍕', '🍔', '🍜', '🍱', '�', '🍗', '🥗',
    '🍨', '🍰', '🛏️', '🏖️', '🏔️', '🚗', '✈️', '🚆',
    '🛶', '🚤', '🎡', '🎢', '🎭', '🎪', '🎨', '🎬',
    '🥂', '🍷', '🍺', '☕', '🨑', '🏡', '🏠', '🏙️',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              onEmojiSelected(_emojis[index]);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(_emojis[index], style: const TextStyle(fontSize: 24))),
            ),
          );
        },
      ),
    );
  }
}