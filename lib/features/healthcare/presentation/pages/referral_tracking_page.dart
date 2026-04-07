import 'package:flutter/material.dart';
import 'package:afyalink/core/theme.dart';

class ReferralTrackingPage extends StatelessWidget {
  const ReferralTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock referral data for tracking
    final mockReferrals = [
      {
        'patient': 'John Doe',
        'target': 'City General Hospital',
        'type': 'Cardiology Consultation',
        'status': 'PENDING',
        'next_steps': 'Patient has not scheduled an appointment. Consider sending a reminder message.',
      },
      {
        'patient': 'Jane Smith',
        'target': 'AfyaLink Pharmacy',
        'type': 'Medication Fulfilment',
        'status': 'COMPLETED',
        'next_steps': 'Service provided. Review notes and follow-up.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Tracking'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockReferrals.length,
        itemBuilder: (context, index) {
          final ref = mockReferrals[index];
          final isPending = ref['status'] == 'PENDING';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(
                'Referral: ${ref['patient']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${ref['target']} - ${ref['type']}'),
              trailing: Chip(
                label: Text(
                  ref['status']!,
                  style: TextStyle(
                    color: isPending ? Colors.orange.shade900 : Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Next Steps:',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(ref['next_steps']!),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPending)
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reminder sent to patient!')),
                                );
                              },
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('Send Reminder'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('View Details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
