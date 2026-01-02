import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'add_activity/manual_add_tab.dart';
import 'add_activity/ai_add_tab.dart';

Future<void> navigateToAddActivityPage(
  BuildContext context, {
  required int tripId,
  required List<Map<String, dynamic>> members,
  required Function(Map<String, dynamic>) onActivityAdded,
}) async {
  await Navigator.push(
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

class _AddActivityPageState extends State<AddActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isSubmitting = false;

  // Key untuk mengakses fungsi submit() di dalam child widgets
  final GlobalKey _manualTabKey = GlobalKey();
  final GlobalKey<AiAddTabState> _aiTabKey = GlobalKey<AiAddTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listener ini penting agar tombol bawah berubah teksnya saat geser tab
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sesuaikan dengan design
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: AppColors.trivaBlue,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        title: const Text(
          'Add Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // TAB SWITCHER
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 40,
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Manual'),
                Tab(text: 'Smart Add ✨'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: MANUAL (Pasang key disini!)
                ManualAddTab(
                  key:
                      _manualTabKey, // PENTING: Agar parent bisa panggil submit()
                  tripId: widget.tripId,
                  members: widget.members,
                  onActivityAdded: widget.onActivityAdded,
                  onSubmitting: (v) => setState(() => _isSubmitting = v),
                ),

                // TAB 2: AI (Pasang key disini!)
                AiAddTab(
                  key: _aiTabKey, // PENTING: Agar parent bisa panggil submit()
                  tripId: widget.tripId,
                  members: widget.members,
                  onProcessingChanged: (val) =>
                      setState(() => _isSubmitting = val),
                ),
              ],
            ),
          ),
        ],
      ),

      // BOTTOM BUTTON (Single Source of Truth)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            // LOGIC PINTAR: Cek tab mana yang aktif
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_tabController.index == 0) {
                      // Kalau di Tab Manual, panggil fungsi submit milik ManualAddTab
                      // Pastikan ManualAddTabState punya method submit() yang public
                      (_manualTabKey.currentState as dynamic)?.submit();
                    } else {
                      // Kalau di Tab AI, panggil fungsi submit milik AiAddTab
                      _aiTabKey.currentState?.submit();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trivaBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                // TEXT BERUBAH SESUAI TAB
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _tabController.index == 0
                          ? 'Save Expenses'
                          : 'Scan & Analyze 🪄',
                      key: ValueKey(
                        _tabController.index,
                      ), // Biar ada animasi ganti text
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
