import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../core/theme/app_colors.dart';
import 'trip_created_sheet.dart';
import '../../core/widgets/add_member_sheet.dart';
import '../../../core/services/trip_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreateTripSheet extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateTripSheet({super.key, this.onSuccess});

  @override
  State<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<CreateTripSheet> {
  // ❌ Hapus _nameController yang tidak terpakai
  // final _nameController = TextEditingController();

  final _tripNameController = TextEditingController();

  // State Tanggal Trip
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  bool _isLoading = false;

  final List<Map<String, dynamic>> _participants = [
    {'name': 'You', 'isCurrentUser': true, 'isGuest': false},
  ];

  // State Image
  int _selectedCoverIndex = -1;
  File? _pickedImageFile;

  // ✅ CUKUP SATU KALI DEKLARASI DI SINI
  final ImagePicker _picker = ImagePicker();

  // List Gambar Pilihan Unsplash (Static)
  final List<String> _coverImages = [
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=600',
    'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?w=600',
    'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=600',
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600',
  ];

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  void _addParticipant(Map<String, dynamic> participant) {
    final isDuplicate = _participants.any(
      (p) =>
          p['name'].toString().toLowerCase() ==
          participant['name'].toString().toLowerCase(),
    );
    if (!isDuplicate) {
      setState(() => _participants.add(participant));
    }
  }

  void _removeParticipant(int index) {
    if (index > 0) {
      setState(() => _participants.removeAt(index));
    }
  }

  void _showAddMemberSheet() {
    showAddMemberSheet(
      context,
      onAddMember: _addParticipant,
      excludeNames: _participants.map((p) => p['name'] as String).toList(),
    );
  }

  String get _dateRangeText {
    final start = DateFormat('d MMM').format(_startDate);
    final end = DateFormat('d MMM').format(_endDate);
    if (start == end) return start;
    return '$start - $end';
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                'Select Trip Dates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.range,
                  initialSelectedRange: PickerDateRange(_startDate, _endDate),
                  minDate: DateTime.now().subtract(const Duration(days: 365)),
                  maxDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  headerStyle: const DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  monthCellStyle: const DateRangePickerMonthCellStyle(
                    todayTextStyle: TextStyle(
                      color: AppColors.trivaBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  startRangeSelectionColor: AppColors.trivaBlue,
                  endRangeSelectionColor: AppColors.trivaBlue,
                  rangeSelectionColor: AppColors.trivaBlue.withOpacity(0.1),
                  onSelectionChanged:
                      (DateRangePickerSelectionChangedArgs args) {
                        if (args.value is PickerDateRange) {
                          setState(() {
                            _startDate = args.value.startDate ?? DateTime.now();
                            _endDate = args.value.endDate ?? _startDate;
                          });
                        }
                      },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.trivaBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm Dates'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDone() async {
    // 1. Validasi Nama
    final name = _tripNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a trip name')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? selectedUrl;

      if (_pickedImageFile == null && _selectedCoverIndex >= 0) {
        selectedUrl = _coverImages[_selectedCoverIndex];
      }

      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final tripId = await TripService().createTripWithMembers(
        name: name,
        startDate: startDateStr,
        endDate: endDateStr,
        members: _participants,
        coverFile: _pickedImageFile, 
        coverUrl: selectedUrl, 
      );

      if (mounted) setState(() => _isLoading = false);

      if (tripId != null) {
        widget.onSuccess?.call();
        if (!mounted) return;
        Navigator.pop(context);

        showTripCreatedSheet(
          context,
          tripId: tripId,
          tripName: name,
          tripEmoji: '✈️',
          participants: _participants,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create trip. Try again.')),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres sedikit
      );
      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
          _selectedCoverIndex = -1;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
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
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.trivaBlue,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const Text(
                        'New Trip',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : TextButton(
                              onPressed: _handleDone,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 40),
                              ),
                              child: const Text(
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

            // --- CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COVER IMAGE ---
                    const Text(
                      'Trip Cover',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _coverImages.length + 1, // +1 untuk tombol upload
                        itemBuilder: (context, index) {
                          // ITEM 0: TOMBOL UPLOAD / HASIL UPLOAD
                          if (index == 0) {
                            bool isFileSelected = _selectedCoverIndex == -1;
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isFileSelected
                                        ? AppColors.trivaBlue
                                        : Colors.grey[300]!,
                                    width: isFileSelected ? 2 : 1,
                                  ),
                                ),
                                child:
                                    _pickedImageFile != null && isFileSelected
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _pickedImageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_rounded,
                                            color: isFileSelected
                                                ? AppColors.trivaBlue
                                                : Colors.grey,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Upload",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isFileSelected
                                                  ? AppColors.trivaBlue
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          }

                          // ITEM 1 dst: GAMBAR UNSPLASH
                          final unsplashIndex = index - 1;
                          bool isSelected =
                              _selectedCoverIndex == unsplashIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCoverIndex = unsplashIndex;
                                _pickedImageFile = null; // Reset file upload
                              });
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.trivaBlue
                                      : Colors.transparent,
                                  width: 2, // Highlight kalau dipilih
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _coverImages[unsplashIndex],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- TRIP NAME & DATE ROW (REFACTORED) ---
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // 1. INPUT TEXT (REFACTORED: NO WRAPPER CONTAINER)
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _tripNameController,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Trip Name',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              // Vertical 13 + fontSize 16 + default line height ~= 48px
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.trivaBlue,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 2. DATE BUTTON (REFACTORED: MATCHING STYLE)
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _showDateRangePicker,
                            child: Container(
                              height: 48, // Tinggi disamakan manual
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: AppColors.trivaBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _dateRangeText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- PARTICIPANTS ---
                    const Text(
                      'Participants',
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_participants.length, (index) {
                            final participant = _participants[index];
                            final isCurrentUser =
                                participant['isCurrentUser'] == true;

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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              participant['name'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isCurrentUser
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (isCurrentUser) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Admin',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (!isCurrentUser)
                                        GestureDetector(
                                          onTap: () =>
                                              _removeParticipant(index),
                                          child: const Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            color: AppColors.border.withOpacity(0.3),
                            indent: 16,
                          ),
                          InkWell(
                            onTap: _showAddMemberSheet,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.trivaBlue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Member',
                                    style: TextStyle(
                                      fontSize: 16,
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

void showCreateTripSheet(BuildContext context, {VoidCallback? onSuccess}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => CreateTripSheet(onSuccess: onSuccess),
  );
}
