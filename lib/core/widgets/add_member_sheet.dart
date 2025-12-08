import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable Add Member Bottom Sheet
/// Can be used in both Create Trip and Trip Detail
class AddMemberSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddMember;
  final List<String>? excludeNames; // Untuk exclude member yang sudah ada
  
  const AddMemberSheet({
    super.key,
    required this.onAddMember,
    this.excludeNames,
  });

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _searchController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _guestContactController = TextEditingController();
  bool _isAddingGuest = false;
  
  // Mock data existing users
  final List<Map<String, String>> _existingUsers = [
    {'name': 'Isna', 'username': '@isna'},
    {'name': 'Budi', 'username': '@budi'},
    {'name': 'Siti', 'username': '@siti'},
    {'name': 'Andi', 'username': '@andi'},
    {'name': 'Ahmad', 'username': '@ahmad'},
    {'name': 'Risa', 'username': '@risa'},
    {'name': 'Amanda', 'username': '@amanda'},
  ];
  
  List<Map<String, String>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filterUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _guestNameController.dispose();
    _guestContactController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    setState(() {
      var users = _existingUsers;
      
      // Exclude members that already exist
      if (widget.excludeNames != null && widget.excludeNames!.isNotEmpty) {
        users = users.where((user) {
          return !widget.excludeNames!.any((name) => 
            name.toLowerCase() == user['name']!.toLowerCase()
          );
        }).toList();
      }
      
      // Filter by search query
      if (_searchController.text.isEmpty) {
        _filteredUsers = users;
      } else {
        _filteredUsers = users.where((user) {
          return user['name']!
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
        }).toList();
      }
    });
  }

  void _addExistingUser(Map<String, String> user) {
    widget.onAddMember({
      'name': user['name']!,
      'username': user['username'],
      'isCurrentUser': false,
      'isGuest': false,
    });
    Navigator.pop(context);
  }

  void _addGuest() {
    if (_guestNameController.text.isNotEmpty) {
      widget.onAddMember({
        'name': _guestNameController.text.trim(),
        'contact': _guestContactController.text.trim(),
        'isCurrentUser': false,
        'isGuest': true,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
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
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 40),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.trivaBlue,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        _isAddingGuest ? 'Add Guest' : 'Add Member',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_isAddingGuest)
                        TextButton(
                          onPressed: _addGuest,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(60, 40),
                          ),
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.trivaBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 60),
                    ],
                  ),
                ],
              ),
            ),

            if (!_isAddingGuest) ...[
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Existing users list
              Expanded(
                child: _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No friends found',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return InkWell(
                            onTap: () => _addExistingUser(user),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.trivaBlue.withValues(alpha: 0.1),
                                    child: Text(
                                      user['name']![0].toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.trivaBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name']!,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user['username']!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.trivaBlue,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Add Guest button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isAddingGuest = true;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.trivaBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Add Guest (No Account)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.trivaBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Guest form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guest Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _guestNameController,
                          style: const TextStyle(fontSize: 17),
                          decoration: InputDecoration(
                            hintText: 'Enter guest name',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Contact (WhatsApp/Phone)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _guestContactController,
                          style: const TextStyle(fontSize: 17),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Enter phone number',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper function to show Add Member sheet
void showAddMemberSheet(
  BuildContext context, {
  required Function(Map<String, dynamic>) onAddMember,
  List<String>? excludeNames,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => AddMemberSheet(
      onAddMember: onAddMember,
      excludeNames: excludeNames,
    ),
  );
}