import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmojiPickerSheet extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;

  const EmojiPickerSheet({
    super.key,
    required this.onEmojiSelected,
  });

  // Daftar Emoji Lengkap
  static const List<String> _emojis = [
    // Travel & Places
    '✈️', '🚗', '🏝️', '🏔️', '🏖️', '🗽', '🗼', '🏰', '⛺', '🏠', '🏨', '🏥', '🏦', '🏟️', '🎡', '🎢', '🎠',
    '🗺️', '🧭', '🚧', '🚦', '⛽', '🚀', '🚁', '🚂', '🚆', '🚇', '🚌', '🚍', '🚎', '🚐', '🚑', '🚒', 
    '🚓', '🚕', '🚖', '🏎️', '🏍️', '🛵', '🚲', '🛴', '🚏', '🛤️', '⛽', '🚨', '🚥', '🛑', '🚧', '⚓', '⛵', 
    '🛶', '🚤', '🛳️', '⛴️', '🛥️', '🚢', '🛩️', '🛫', '🛬', '💺', 
    
    // Activities & Objects
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', 
    '🏏', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷', '⛸️', '🥌', '🎿', 
    '⛷️', '🏂', '🪂', '🏋️', '🤼', '🤸', '⛹️', '🤺', '🤾', '🏌️', '🏇', '🧘', '🏄', '🏊', '🤽', '🚣', 
    '🧗', '🚵', '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🎫', '🎟️', '🎪', '🤹', '🎭', '🎨', '🎬', 
    '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸', '🪕', '🎻', '🎲', '♟️', '🎯', '🎳', '🎮', '🎰', '🧩',
    
    // Food & Drink
    '🍽️', '☕', '🍻', '🥂', '🍷', '🍕', '🍔', '🍟', '🌭', '🍿', '🧂', '🥓', '🥚', '🍳', '🧇', '🥞', 
    '🧈', '🍞', '🥐', '🥨', '🥯', '🥖', '🧀', '🥗', '🥪', '🌮', '🌯', '🥫', '🍖', '🍗', '🥩', 
    '🍠', '🥟', '🥠', '🥡', '🍱', '🍘', '🍙', '🍚', '🍛', '🍜', '🦪', '🍣', '🍤', '🍥', '🥮', '🍡', 
    '🥟', '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🧁', '🥧', '🍮', '🍭', '🍬', '🍫', '🍿', '🍩',
    
    // Objects & Symbols
    '💰', '💵', '💳', '💎', '💡', '🔦', '🕯️', '🧾', '🛒', '🛍️', '🎁', '🎈', '🎉', '🎊', '🎀', '🧧', 
    '🧨', '🎐', '🎏', '🎎', '🎍', '🎋', '🎑', '🎓', '🧢', '⛑️', '📿', '💄', '💍', 
    '🌂', '☂️', '💼', '👜', '👝', '🛍️', '🎒', '👞', '👟', '🥾', '🥿', '👠', '👡', '🩰', '👢', '👑', 
    '👒', '🎩', '🎓', '🧢', '⛑️', '📿', '💄', '💍', '💎',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Grid Emoji
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => onEmojiSelected(_emojis[index]),
                child: Container(
                  decoration: BoxDecoration(
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
                  alignment: Alignment.center,
                  child: Text(
                    _emojis[index],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper global function untuk memanggil sheet ini dengan mudah
void showEmojiPickerSheet(BuildContext context, {required Function(String) onSelected}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => EmojiPickerSheet(
      onEmojiSelected: (emoji) {
        onSelected(emoji);
        Navigator.pop(context); // Tutup sheet setelah memilih
      },
    ),
  );
}