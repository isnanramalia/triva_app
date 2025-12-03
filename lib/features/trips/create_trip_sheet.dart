import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'trip_created_sheet.dart';

class CreateTripSheet extends StatefulWidget {
  const CreateTripSheet({super.key});

  @override
  State<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<CreateTripSheet> {
  final _tripNameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🏖️');
  final List<Map<String, dynamic>> _participants = [
    {
      'name': 'Neena',
      'isCurrentUser': true,
      'isGuest': false,
    }
  ];

  @override
  void dispose() {
    _tripNameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _addParticipant(Map<String, dynamic> participant) {
    // Check for duplicate
    final isDuplicate = _participants.any((p) => 
      p['name'].toString().toLowerCase() == participant['name'].toString().toLowerCase()
    );
    
    if (!isDuplicate) {
      setState(() {
        _participants.add(participant);
      });
    }
  }

  void _removeParticipant(int index) {
    if (index > 0) {
      setState(() {
        _participants.removeAt(index);
      });
    }
  }

  void _showAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddMemberSheet(
        onAddMember: _addParticipant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                  // Header buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.trivaBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const Text(
                        'Add new trip',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_tripNameController.text.isNotEmpty) {
                            // Close create trip sheet
                            Navigator.pop(context);
                            // Show success sheet
                            showTripCreatedSheet(
                              context,
                              tripName: _tripNameController.text,
                              tripEmoji: _emojiController.text,
                              participants: _participants,
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.trivaBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Your Trip
                    const Text(
                      'Name Your Trip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Trip name input (2 fields: emoji + name)
                    Row(
                      children: [
                        // Emoji field
                        Container(
                          width: 56,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _emojiController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              maxLength: 2,
                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Name field
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _tripNameController,
                              style: const TextStyle(
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'E.g. Beach Trip',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.3),
                                  fontSize: 17,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Participants
                    const Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Participants container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          // List participants
                          ...List.generate(_participants.length, (index) {
                            final participant = _participants[index];
                            final isCurrentUser = participant['isCurrentUser'] == true;
                            final isGuest = participant['isGuest'] == true;
                            
                            return Column(
                              children: [
                                if (index > 0)
                                  Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    color: AppColors.border.withOpacity(0.3),
                                    indent: 16,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              participant['name'],
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (isCurrentUser || isGuest) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                isCurrentUser ? 'Admin' : 'Guest',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (!isCurrentUser)
                                        GestureDetector(
                                          onTap: () => _removeParticipant(index),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: AppColors.border.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                          
                          // Divider before Add Member
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            color: AppColors.border.withOpacity(0.3),
                            indent: 16,
                          ),
                          
                          // Add Member button
                          InkWell(
                            onTap: _showAddMemberSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Add Member',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.trivaBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet untuk add member
class _AddMemberSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddMember;
  
  const _AddMemberSheet({required this.onAddMember});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
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
  ];
  
  List<Map<String, String>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _existingUsers;
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
      if (_searchController.text.isEmpty) {
        _filteredUsers = _existingUsers;
      } else {
        _filteredUsers = _existingUsers.where((user) {
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
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary.withOpacity(0.5),
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
                child: ListView.builder(
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
                              backgroundColor: AppColors.trivaBlue.withOpacity(0.1),
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
                                      color: AppColors.textSecondary.withOpacity(0.6),
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
                child: Padding(
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
                              color: AppColors.textSecondary.withOpacity(0.3),
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
                              color: AppColors.textSecondary.withOpacity(0.3),
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

/// Helper function
void showCreateTripSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.3),
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const CreateTripSheet(),
  );
}