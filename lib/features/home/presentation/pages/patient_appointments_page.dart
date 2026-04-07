import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/appointments/presentation/pages/chat_page.dart';
import 'package:app/features/healthcare/presentation/widgets/instant_call_button.dart';
import 'package:app/features/healthcare/presentation/pages/meeting_page.dart';

class PatientAppointmentsPage extends ConsumerStatefulWidget {
  const PatientAppointmentsPage({super.key});

  @override
  ConsumerState<PatientAppointmentsPage> createState() => _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends ConsumerState<PatientAppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(patientAppointmentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryTeal,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Accomplished'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Transferred'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        data: (all) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(all.where((a) => a.status.toLowerCase() == 'confirmed').toList()),
              _buildList(all.where((a) => a.status.toLowerCase() == 'pending').toList()),
              _buildList(all.where((a) => a.status.toLowerCase() == 'completed' || a.status.toLowerCase() == 'accomplished').toList(), isPast: true),
              _buildList(all.where((a) => a.status.toLowerCase() == 'cancelled' || a.status.toLowerCase() == 'rejected').toList(), isPast: true),
              _buildList(all.where((a) => a.isTransferred).toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildList(List<Appointment> items, {bool isPast = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No records found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final a = items[index];
        return _AppointmentCard(appointment: a, isPast: isPast);
      },
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final Appointment appointment;
  final bool isPast;

  const _AppointmentCard({required this.appointment, required this.isPast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final isVideo = appointment.type.toLowerCase() == 'telemedicine' || appointment.type.toLowerCase() == 'video';
    
    // Logic for early meeting join (30 mins before)
    final now = DateTime.now();
    final canJoinEarly = !isPast && 
        appointment.status.toLowerCase() == 'confirmed' &&
        appointment.date.subtract(const Duration(minutes: 30)).isBefore(now) &&
        appointment.date.add(const Duration(hours: 2)).isAfter(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                  child: Icon(isVideo ? Icons.video_call : Icons.local_hospital, color: AppTheme.primaryTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(appointment.specialization, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateFormat.format(appointment.date), style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (appointment.isTransferred && appointment.transferredFrom != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Transferred from ${appointment.transferredFrom}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isPast && appointment.status.toLowerCase() == 'confirmed') ...[
                  if (isVideo) 
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canJoinEarly 
                          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingPage(appointmentId: appointment.id)))
                          : null,
                        icon: const Icon(Icons.video_call),
                        label: Text(canJoinEarly ? 'Start Meeting' : 'Join at ${DateFormat('h:mm a').format(appointment.date)}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canJoinEarly ? AppTheme.primaryTeal : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('Get Directions'),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
                if (!isPast && (appointment.status.toLowerCase() == 'confirmed' || appointment.status.toLowerCase() == 'pending'))
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(appointmentId: appointment.id))),
                    icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryTeal),
                    tooltip: 'Chat with Specialist',
                  ),
                if (isPast && (appointment.status.toLowerCase() == 'completed' || appointment.status.toLowerCase() == 'accomplished'))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(context, ref, appointment),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Rate Service'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    final s = status.toLowerCase();
    if (s == 'confirmed' || s == 'completed' || s == 'accomplished') color = Colors.green;
    if (s == 'pending' || s == 'processing') color = Colors.orange;
    if (s == 'cancelled' || s == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
  
  void _showRatingDialog(BuildContext context, WidgetRef ref, Appointment appointment) {
    int rating = 0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate your visit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience with ${appointment.doctorName}?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, size: 32, color: Colors.amber),
                  onPressed: () => setState(() => rating = index + 1),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment (required)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: rating > 0 && commentController.text.isNotEmpty ? () async {
                final repo = ref.read(appointmentRepositoryProvider);
                final success = await repo.createReview(
                  appointment.doctorUserId ?? '', 
                  rating, 
                  commentController.text
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Thank you for your feedback!' : 'Failed to submit review'))
                  );
                }
              } : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

final patientAppointmentsListProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.fetchMyAppointments();
});
