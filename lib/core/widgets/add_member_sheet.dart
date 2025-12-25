import 'dart:async'; // Untuk Debounce
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/trip_service.dart'; // Pastikan import service

class AddMemberSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddMember;
  final List<String>? excludeNames;

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

  // Guest Controllers
  final _guestNameController = TextEditingController();
  final _guestContactController = TextEditingController();

  bool _isAddingGuest = false;
  bool _isLoading = false;
  Timer? _debounce; // Timer untuk delay search

  // Data user hasil search API
  List<Map<String, dynamic>> _userResults = [];

  @override
  void initState() {
    super.initState();
    // Load awal (kosong atau suggest user populer jika mau)
    _searchUsers('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _guestNameController.dispose();
    _guestContactController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ✅ LOGIC SEARCH USER KE API
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Tunggu 500ms setelah user berhenti mengetik baru panggil API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);

    try {
      // Panggil Service
      final users = await TripService().searchUsers(query);

      if (mounted) {
        setState(() {
          // Filter user yang sudah ada di list trip (exclude)
          if (widget.excludeNames != null && widget.excludeNames!.isNotEmpty) {
            _userResults = users
                .where(
                  (u) => !widget.excludeNames!.any(
                    (name) =>
                        name.toLowerCase() ==
                        u['name'].toString().toLowerCase(),
                  ),
                )
                .toList();
          } else {
            _userResults = users;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add Registered User
  void _addExistingUser(Map<String, dynamic> user) {
    widget.onAddMember({
      'name': user['name'],
      'email': user['email'], // Penting buat invite real user
      'username': user['username'],
      'isCurrentUser': false,
      'isGuest': false,
    });
    Navigator.pop(context);
  }

  // ✅ LOGIC ADD GUEST (VALIDASI WA)
  void _addGuest() {
    final name = _guestNameController.text.trim();
    final contact = _guestContactController.text.trim();

    if (name.isEmpty) {
      _showError('Guest name is required');
      return;
    }

    if (contact.isEmpty) {
      _showError('WhatsApp number is required for recap');
      return;
    }

    widget.onAddMember({
      'name': name,
      'contact': contact,
      'isCurrentUser': false,
      'isGuest': true, // Tandai sebagai guest
    });
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // HEADER
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
                        child: const Text(
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

                      // Tombol Add khusus mode Guest
                      if (_isAddingGuest)
                        TextButton(
                          onPressed: _addGuest,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(60, 40),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.trivaBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 60), // Dummy spacing
                    ],
                  ),
                ],
              ),
            ),

            // CONTENT
            if (!_isAddingGuest) ...[
              // 1. MODE CARI USER (MEMBER)

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged, // Panggil API saat ngetik
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
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

              // List User Result
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _userResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _userResults.length,
                        itemBuilder: (context, index) {
                          final user = _userResults[index];
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
                                    backgroundColor: AppColors.trivaBlue
                                        .withOpacity(0.1),
                                    child: Text(
                                      (user['name'] as String)[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.trivaBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'],
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
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

              // Tombol Switch ke Guest
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isAddingGuest = true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.trivaBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
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
              // 2. MODE ADD GUEST (FORM)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guest Name
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

                      // Contact (WA)
                      const Text(
                        'WhatsApp Number',
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
                          keyboardType: TextInputType.phone, // Keyboard angka
                          decoration: InputDecoration(
                            hintText: 'e.g. 08123456789',
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

                      const SizedBox(height: 8),
                      Text(
                        '* Required for sending trip summary later.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
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

void showAddMemberSheet(
  BuildContext context, {
  required Function(Map<String, dynamic>) onAddMember,
  List<String>? excludeNames,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) =>
        AddMemberSheet(onAddMember: onAddMember, excludeNames: excludeNames),
  );
}
