import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import '../../data/repositories/availability_repository.dart';

class WeeklySchedulePage extends ConsumerStatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  ConsumerState<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends ConsumerState<WeeklySchedulePage> {
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // Map of dayIndex to list of slots
  Map<int, List<WeeklySlot>> _localSlots = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final slots = await ref.read(availabilityRepositoryProvider).fetchMyWeeklyAvailability();
    final Map<int, List<WeeklySlot>> map = {};
    for (int i = 0; i < 7; i++) {
      map[i] = slots.where((s) => s.dayOfWeek == i).toList();
    }
    setState(() {
      _localSlots = map;
      _isLoading = false;
    });
  }

  void _addSlot(int dayIndex) {
    setState(() {
      _localSlots[dayIndex]!.add(WeeklySlot(
        dayOfWeek: dayIndex,
        startTime: '09:00',
        endTime: '17:00',
      ));
    });
  }

  void _removeSlot(int dayIndex, int slotIndex) {
    setState(() {
      _localSlots[dayIndex]!.removeAt(slotIndex);
    });
  }

  Future<void> _selectTime(int dayIndex, int slotIndex, bool isStart) async {
    final slot = _localSlots[dayIndex]![slotIndex];
    final currentStr = isStart ? slot.startTime : slot.endTime;
    final currentTime = TimeOfDay(
      hour: int.parse(currentStr.split(':')[0]),
      minute: int.parse(currentStr.split(':')[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        final currentSlot = _localSlots[dayIndex]![slotIndex];
        _localSlots[dayIndex]![slotIndex] = WeeklySlot(
          dayOfWeek: dayIndex,
          startTime: isStart ? newTime : currentSlot.startTime,
          endTime: isStart ? currentSlot.endTime : newTime,
        );
      });
    }
  }

  Future<void> _save() async {
    try {
      final List<WeeklySlot> allSlots = [];
      _localSlots.forEach((_, slots) => allSlots.addAll(slots));
      
      await ref.read(availabilityRepositoryProvider).updateWeeklyAvailability(allSlots);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly schedule updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Availability', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayName = _days[index];
              final slots = _localSlots[index] ?? [];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => _addSlot(index),
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryTeal),
                          ),
                        ],
                      ),
                      if (slots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Unavailable', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        )
                      else
                        ...slots.asMap().entries.map((entry) {
                          final slotIdx = entry.key;
                          final slot = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(index, slotIdx, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(slot.startTime, textAlign: TextAlign.center),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(index, slotIdx, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(slot.endTime, textAlign: TextAlign.center),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeSlot(index, slotIdx),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
