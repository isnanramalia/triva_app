import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'trip_created_sheet.dart';
import '../../core/widgets/add_member_sheet.dart';

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
    showAddMemberSheet(
      context,
      onAddMember: _addParticipant,
      excludeNames: _participants.map((p) => p['name'] as String).toList(),
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
                                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  fontSize: 17,
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
                                    color: AppColors.border.withValues(alpha: 0.3),
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
                                                  color: AppColors.textSecondary.withValues(alpha: 0.6),
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
                                              color: AppColors.border.withValues(alpha: 0.5),
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
                            color: AppColors.border.withValues(alpha: 0.3),
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

/// Helper function
void showCreateTripSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const CreateTripSheet(),
  );
}