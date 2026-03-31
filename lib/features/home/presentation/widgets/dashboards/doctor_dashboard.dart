import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';

class DoctorDashboard extends ConsumerWidget {
  final User user;
  const DoctorDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Dashboard Hero
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryTeal,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('lib/assets/images/doctor_dashboard_hero.png', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.4)),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Welcome Back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                      Text('Dr. ${user.fullName}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(user.doctorProfile?.specialty ?? 'Medical Practitioner', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today\'s Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Appointments', '12', Icons.calendar_today, Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard('Patients', '45', Icons.people, Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Messages', '5', Icons.message, Colors.purple),
                    const SizedBox(width: 16),
                    _buildStatCard('Revenue', '850k', Icons.attach_money, Colors.green),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Upcoming Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildAppointmentItem('John Doe', '10:30 AM', 'General Checkup'),
                _buildAppointmentItem('Jane Smith', '11:45 AM', 'Follow-up'),
                _buildAppointmentItem('Robert Brown', '02:00 PM', 'Consultation'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String patient, String time, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.primaryTeal.withOpacity(0.1), child: Text(patient[0])),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(type, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
