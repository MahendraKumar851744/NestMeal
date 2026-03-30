import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/slot_provider.dart';

class SlotManagementScreen extends StatefulWidget {
  const SlotManagementScreen({super.key});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final cookId = context.read<AuthProvider>().currentUser?.cookProfile?.id;
    if (cookId == null) return;
    final slotProvider = context.read<SlotProvider>();
    try {
      await Future.wait([
        slotProvider.fetchPickupSlots(cookId: cookId),
        slotProvider.fetchDeliverySlots(cookId: cookId),
      ]);
    } catch (_) {}
  }

  Future<void> _showAddSlotDialog(String slotType) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 11, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 13, minute: 0);
    final maxOrdersController = TextEditingController(text: '10');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Add ${slotType == 'pickup' ? 'Pickup' : 'Delivery'} Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today,
                          color: AppTheme.primaryOrange),
                      title: Text(
                          DateFormat('EEE, MMM d, y').format(selectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),
                    // Start time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time,
                          color: AppTheme.primaryOrange),
                      title: Text('Start: ${startTime.format(ctx)}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setDialogState(() => startTime = time);
                        }
                      },
                    ),
                    // End time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_filled,
                          color: AppTheme.primaryOrange),
                      title: Text('End: ${endTime.format(ctx)}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: endTime,
                        );
                        if (time != null) {
                          setDialogState(() => endTime = time);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: maxOrdersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Orders',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: TextStyle(color: AppTheme.greyText)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _createSlot(
                      slotType,
                      selectedDate,
                      startTime,
                      endTime,
                      int.tryParse(maxOrdersController.text) ?? 10,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                  ),
                  child: const Text('Create Slot'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createSlot(String slotType, DateTime date,
      TimeOfDay startTime, TimeOfDay endTime, int maxOrders) async {
    final cookId = context.read<AuthProvider>().currentUser?.cookProfile?.id;
    if (cookId == null) return;

    final slotProvider = context.read<SlotProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

    try {
      await slotProvider.createSlot(
        slotType: slotType,
        cookId: cookId,
        date: dateStr,
        startTime: startStr,
        endTime: endStr,
        maxOrders: maxOrders,
      );
      await _loadSlots();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${slotType == 'pickup' ? 'Pickup' : 'Delivery'} slot created!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotProvider = context.watch<SlotProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Text(
          'Manage Slots',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Pickup Slots'),
            Tab(text: 'Delivery Slots'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0 ? 'pickup' : 'delivery';
          _showAddSlotDialog(type);
        },
        backgroundColor: AppTheme.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pickup slots
          RefreshIndicator(
            onRefresh: _loadSlots,
            color: AppTheme.primaryOrange,
            child: slotProvider.isLoading && slotProvider.pickupSlots.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : slotProvider.pickupSlots.isEmpty
                    ? _buildEmptyState('No pickup slots', 'Tap + to add one')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: slotProvider.pickupSlots.length,
                        itemBuilder: (ctx, i) {
                          final slot = slotProvider.pickupSlots[i];
                          return _buildSlotCard(
                            date: slot.date,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                            maxOrders: slot.maxOrders,
                            bookedOrders: slot.bookedOrders,
                            status: slot.status,
                            type: 'Pickup',
                          );
                        },
                      ),
          ),
          // Delivery slots
          RefreshIndicator(
            onRefresh: _loadSlots,
            color: AppTheme.primaryOrange,
            child: slotProvider.isLoading && slotProvider.deliverySlots.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : slotProvider.deliverySlots.isEmpty
                    ? _buildEmptyState(
                        'No delivery slots', 'Tap + to add one')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: slotProvider.deliverySlots.length,
                        itemBuilder: (ctx, i) {
                          final slot = slotProvider.deliverySlots[i];
                          return _buildSlotCard(
                            date: slot.date,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                            maxOrders: slot.maxOrders,
                            bookedOrders: slot.bookedOrders,
                            status: slot.status,
                            type: 'Delivery',
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: AppTheme.greyText),
          const SizedBox(height: 16),
          Text(title,
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.greyText)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 14, color: AppTheme.greyText)),
        ],
      ),
    );
  }

  Widget _buildSlotCard({
    required String date,
    required String startTime,
    required String endTime,
    required int maxOrders,
    required int bookedOrders,
    required String status,
    required String type,
  }) {
    final statusColor = switch (status) {
      'open' => AppTheme.successGreen,
      'full' => AppTheme.primaryOrange,
      'cancelled' => AppTheme.errorRed,
      _ => AppTheme.greyText,
    };

    String formattedDate;
    try {
      formattedDate = DateFormat('EEE, MMM d').format(DateTime.parse(date));
    } catch (_) {
      formattedDate = date;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              type == 'Pickup' ? Icons.store_outlined : Icons.delivery_dining,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(fontSize: 13, color: AppTheme.greyText),
                ),
                const SizedBox(height: 4),
                Text(
                  '$bookedOrders / $maxOrders booked',
                  style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
