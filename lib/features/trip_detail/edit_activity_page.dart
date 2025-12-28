import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart';
import '../../../core/widgets/emoji_picker_sheet.dart';

class EditActivityPage extends StatefulWidget {
  final Map<String, dynamic> activity;
  final List<dynamic> members;
  final int tripId;

  const EditActivityPage({
    super.key,
    required this.activity,
    required this.members,
    required this.tripId,
  });

  @override
  State<EditActivityPage> createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedEmoji;
  late DateTime _selectedDate;
  int? _paidByMemberId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final act = widget.activity;

    _titleController.text = act['title']?.toString() ?? '';
    // Laravel mengembalikan total_amount kadang sebagai String/Decimal, kita pastikan jadi String
    _amountController.text = act['total_amount']?.toString() ?? '0';
    _selectedEmoji = act['emoji'] ?? '📝';
    _selectedDate = act['date'] != null
        ? DateTime.parse(act['date'])
        : DateTime.now();

    // Ambil ID member dari objek paid_by jika ada
    if (act['paid_by_member_id'] != null) {
      _paidByMemberId = act['paid_by_member_id'];
    } else if (act['paid_by'] != null) {
      _paidByMemberId = act['paid_by']['id'];
    }
  }

  void _handleSave() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _paidByMemberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isSaving = true);

    final Map<String, dynamic> data = {
      'title': _titleController.text,
      'total_amount': double.tryParse(_amountController.text) ?? 0,
      'emoji': _selectedEmoji,
      'date': _selectedDate.toIso8601String(),
      'paid_by_member_id': _paidByMemberId,
      // Jika ada split_type, pastikan dikirim juga sesuai API
      'split_type': widget.activity['split_type'] ?? 'equally',
    };

    final success = await TripService().updateTransaction(
      widget.tripId,
      widget.activity['id'],
      data,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true); // Balik ke detail dengan flag true
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update activity")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Activity"),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(onPressed: _handleSave, child: const Text("Done")),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UI Form kamu (Title, Amount, Emoji, Date Picker, dsb)
          // Pastikan DropdownButton menggunakan _paidByMemberId
          DropdownButtonFormField<int>(
            value: _paidByMemberId,
            items: widget.members.map((m) {
              return DropdownMenuItem<int>(
                value: m['id'],
                child: Text(m['user']?['name'] ?? m['guest_name'] ?? 'Member'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _paidByMemberId = val),
            decoration: const InputDecoration(labelText: "Paid By"),
          ),
        ],
      ),
    );
  }
}
