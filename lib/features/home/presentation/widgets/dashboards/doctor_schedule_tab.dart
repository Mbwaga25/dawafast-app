import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/profile/data/repositories/availability_repository.dart';
import 'package:intl/intl.dart';

class DoctorScheduleTab extends ConsumerWidget {
  final User user;
  const DoctorScheduleTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final upcoming = appointments.where((a) => a.status != 'cancelled' && a.status != 'accomplished').toList();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Upcoming Appointments'),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                _buildEmptyState('No upcoming sessions for today.')
              else
                ...upcoming.map((a) => _buildAppointmentCard(context, a)),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Calendar Overview'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 48, color: AppTheme.primaryTeal),
                    const SizedBox(height: 12),
                    const Text('Manage Weekly Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Set your consultation hours and breaks', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                         // This is already in Profile tab availability management, 
                         // but we can add a shortcut here if desired.
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Configure Availability', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
          child: const Icon(Icons.video_call, color: AppTheme.primaryTeal),
        ),
        title: Text(a.patientName ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('HH:mm').format(a.date)} - ${a.status.toUpperCase()}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
           // Navigate to detail or meeting
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(message, style: const TextStyle(color: Colors.grey))));
  }
}
