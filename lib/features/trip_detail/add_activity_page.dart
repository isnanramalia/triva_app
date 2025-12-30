import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'add_activity/manual_add_tab.dart';
import 'add_activity/ai_add_tab.dart';

void navigateToAddActivityPage(
  BuildContext context, {
  required int tripId,
  required List<Map<String, dynamic>> members,
  required Function(Map<String, dynamic>) onActivityAdded,
}) {
  Navigator.push(
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
  final GlobalKey _manualTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
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
          // TAB SWITCHER (UI TETAP)
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
                ManualAddTab(
                  key: _manualTabKey,
                  tripId: widget.tripId,
                  members: widget.members,
                  onActivityAdded: widget.onActivityAdded,
                  onSubmitting: (v) => setState(() => _isSubmitting = v),
                ),
                const AiAddTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _tabController.index == 0 && !_isSubmitting
                ? () => (_manualTabKey.currentState as dynamic)?.submit()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trivaBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Add',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
