import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';

class LabDashboard extends ConsumerWidget {
  final User user;
  const LabDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Dashboard Hero
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF673AB7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Diagnostic Lab Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(user.labProfile?.labName ?? 'Advanced Diagnostics', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Daily Test Quota: 85%', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lab Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Pending Tests', '14', Icons.science, Colors.deepPurple),
                    const SizedBox(width: 16),
                    _buildStatCard('Samples', '32', Icons.biotech, Colors.teal),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Reports Issued', '125', Icons.assignment, Colors.orange),
                    const SizedBox(width: 16),
                    _buildStatCard('Equipment', 'Normal', Icons.settings, Colors.blue),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Today\'s Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTestItem('Blood Work', '09:00 AM', 'Ready for Sample'),
                _buildTestItem('COVID-19 RT-PCR', '10:30 AM', 'Processing'),
                _buildTestItem('Lipid Profile', '11:15 AM', 'Completed'),
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
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(String name, String time, String status) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(status, style: TextStyle(color: status == 'Completed' ? Colors.green : AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
