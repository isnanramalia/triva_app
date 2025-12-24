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
  // REVISI: Ganti controller dengan String state untuk emoji
  String _selectedEmoji = '🏖️';
  
  final List<Map<String, dynamic>> _participants = [
    {
      'name': 'Neena',
      'isCurrentUser': true,
      'isGuest': false,
    }
  ];

  // Style Constants
  final double _fieldHeight = 44.0;
  final double _borderRadius = 10.0;

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  void _addParticipant(Map<String, dynamic> participant) {
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

  // REVISI: Emoji Picker dengan daftar lengkap
  void _showEmojiPicker() {
    final List<String> emojis = [
      '🍽️', '🍕', '🍔', '🌭', '🥪', '🌮', '🌯', '🥙', '🍜', '🍲', '🍱', '🍛', '🍙', '🍚', '🍘', '🥟', 
      '🍗', '🥩', '🥓', '🍖', '🥗', '🥦', '🥬', '🥒', '🌽', '🥕', '🥔', '🥖', '🥐', '🍞', '🥯', 
      '🥨', '🥞', '🧇', '🧀', '🥚', '🍳', '🧈', '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🧁', '🥧', 
      '🍫', '🍬', '🍭', '🍮', '🍯', '🍼', '🥛', '☕', '🍵', '🧃', '🥤', '🍺', '🍻', '🥂', '🍷', '🥃', 
      '🍸', '🍹', '🍾', '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚', '🚛', '🚜', 
      '🏍️', '🛵', '🚲', '🛴', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡', '🚠', '🚟', '🚃', '🚋', '🚞', '🚝', 
      '🚄', '🚅', '🚈', '🚂', '🚆', '🚇', '🚊', '🚉', '🚁', '🛩️', '✈️', '🛫', '🛬', '🚀', '🛸', '🛰️', 
      '🛶', '⛵', '🛥️', '🚤', '⛴️', '🛳️', '🚢', '⚓', '⛽', '🚧', '🚦', '🚥', '🚏', '🗺️', '🗿', '🗽', 
      '🗼', '🏰', '🏯', '🏟️', '🎡', '🎢', '🎠', '⛲', '⛱️', '🏖️', '🏝️', '🏜️', '🌋', '⛰️', '🏔️', '🗻', 
      '⛺', '🏠', '🏡', '🏘️', '🏚️', '🏗️', '🏭', '🏢', '🏬', '🏣', '🏤', '🏥', '🏦', '🏨', '🏪', '🏫', 
      '🏩', '💒', '🏛️', '⛪', '🕌', '🛕', '🕍', '🕋', '⛩️', '⚽', '🏀', '🏈', '⚾', '🥎', '🏐', '🏉', 
      '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊', 
      '🥋', '🎽', '🛹', '🛼', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂', '🪂', '🏋️', '🤼', '🤸', '⛹️', '🤺', 
      '🤾', '🏌️', '🏇', '🧘', '🏄', '🏊', '🤽', '🚣', '🧗', '🚵', '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', 
      '🎖️', '🎗️', '🎫', '🎟️', '🎪', '🤹', '🎭', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', 
      '🎸', '🪕', '🎻', '🎲', '♟️', '🎯', '🎳', '🎮', '🎰', '🧩', '❤️', '🧡', '💛', '💚', '💙', '💜', 
      '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', 
      '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎', 
      '♏', '♐', '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳', '🈶', '🈚', '🈸', '🈺', 
      '🈷️', '✴️', '🆚', '💮', '🉐', '㊙️', '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑', 
      '🅾️', '🆘', '❌', '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️', '🚷', '🚯', '🚳', '🚱', '🔞', 
      '📵', '🚭', '❗', '❕', '❓', '❔', '‼️', '⁉️', '🔅', '🔆', '〽️', '⚠️', '🚸', '🔱', '⚜️', '🔰', 
      '♻️', '✅', '🈯', '💹', '❇️', '✳️', '❎', '🌐', '💠', 'Ⓜ️', '🌀', '💤', '🏧', '🚾', '♿', '🅿️', 
      '🈳', '🈂️', '🛂', '🛃', '🛄', '🛅', '🚹', '🚺', '🚼', '🚻', '🚮', '🎦', '📶', '🈁', '🔣', 'ℹ️', 
      '🔤', '🔡', '🔠', '🆖', '🆗', '🆙', '🆒', '🆕', '🆓', '0️⃣', '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', 
      '6️⃣', '7️⃣', '8️⃣', '9️⃣', '🔟', '🔢', '#️⃣', '*️⃣', '⏏️', '▶️', '⏸️', '⏯️', '⏹️', '⏺️', '⏭️', 
      '⏮️', '⏩', '⏪', '⏫', '⏬', '◀️', '🔼', '🔽', '➡️', '⬅️', '⬆️', '⬇️', '↗️', '↘️', '↙️', '↖️', 
      '↕️', '↔️', '↪️', '↩️', '⤴️', '⤵️', '🔀', '🔁', '🔂', '🔄', '🔃', '🎵', '🎶', '➕', '➖', '➗', 
      '✖️', '♾️', '💲', '💱', '™️', '©️', '®️', '👁️‍🗨️', '🔚', '🔙', '🔛', '🔝', '🔜', '〰️', '➰', 
      '➿', '✔️', '☑️', '🔘', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤', '🔺', '🔻', '🔸', 
      '🔹', '🔶', '🔷', '🔳', '🔲', '▪️', '▫️', '◾', '◽', '◼️', '◻️', '🟥', '🟧', '🟨', '🟩', '🟦', 
      '🟪', '🟫', '⬛', '⬜', '🔈', '🔇', '🔉', '🔊', '🔔', '🔕', '📣', '📢', '💬', '💭', '🗯️', '♠️', 
      '♣️', '♥️', '♦️', '🃏', '🎴', '🀄',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, 
                  mainAxisSpacing: 12, 
                  crossAxisSpacing: 12
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () { 
                    setState(() => _selectedEmoji = emojis[index]); 
                    Navigator.pop(context); 
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), 
                    child: Center(child: Text(emojis[index], style: const TextStyle(fontSize: 28)))
                  ),
                ),
              ),
            ),
          ],
        ),
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
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Cancel', style: TextStyle(color: AppColors.trivaBlue, fontSize: 17, fontWeight: FontWeight.w400)),
                      ),
                      const Text(
                        'Add new trip',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_tripNameController.text.isNotEmpty) {
                            Navigator.pop(context);
                            showTripCreatedSheet(
                              context,
                              tripName: _tripNameController.text,
                              tripEmoji: _selectedEmoji, // Gunakan emoji yang dipilih
                              participants: _participants,
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Done', style: TextStyle(color: AppColors.trivaBlue, fontSize: 17, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    const Text('Name Your Trip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    
                    // Input Row
                    Row(
                      children: [
                        // REVISI: Emoji Picker Statis (Tanpa Keyboard/InputDecoration)
                        GestureDetector(
                          onTap: _showEmojiPicker,
                          child: Container(
                            width: 56,
                            height: _fieldHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(_borderRadius),
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
                        
                        // Name Field (Input Bersih tanpa border)
                        Expanded(
                          child: Container(
                            height: _fieldHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(_borderRadius),
                            ),
                            child: TextField(
                              controller: _tripNameController,
                              style: const TextStyle(fontSize: 17, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'E.g. Beach Trip',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                border: InputBorder.none, // Tanpa border/dekorasi
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Label Participants
                    const Text('Participants', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    
                    // Participants List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_participants.length, (index) {
                            final participant = _participants[index];
                            final isCurrentUser = participant['isCurrentUser'] == true;
                            
                            return Column(
                              children: [
                                if (index > 0)
                                  Divider(height: 0.5, thickness: 0.5, color: AppColors.border.withValues(alpha: 0.3), indent: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                            if (isCurrentUser) ...[
                                              const SizedBox(height: 2),
                                              Text('Admin', style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6))),
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
                                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                          
                          Divider(height: 0.5, thickness: 0.5, color: AppColors.border.withValues(alpha: 0.3), indent: 16),
                          
                          InkWell(
                            onTap: _showAddMemberSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text('Add Member', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppColors.trivaBlue)),
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