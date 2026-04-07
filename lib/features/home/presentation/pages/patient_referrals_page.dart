import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:afyalink/features/healthcare/data/models/referral_model.dart';
import 'package:afyalink/features/appointments/data/repositories/appointment_repository.dart';
import 'package:afyalink/features/appointments/presentation/pages/chat_page.dart';

class PatientReferralsPage extends ConsumerWidget {
  const PatientReferralsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(myReferralsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Referrals', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: referralsAsync.when(
        data: (referrals) {
          if (referrals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No referrals found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: referrals.length,
            itemBuilder: (context, index) {
              final referral = referrals[index];
              return _ReferralCard(referral: referral);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ReferralCard extends ConsumerWidget {
  final Referral referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final targetName = referral.targetDoctorName ?? referral.targetStoreName ?? 'Specialist';
    final referringName = referral.referringDoctorName ?? referral.referringStoreName ?? 'Provider';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(referral.status),
                Text(dateFormat.format(referral.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Referred to: $targetName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('From: $referringName', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            
            const Divider(height: 24),
            
            const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
            Text(referral.reason ?? 'No reason provided', style: const TextStyle(fontSize: 14)),
            
            if (referral.notes != null && referral.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
              Text(referral.notes!, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _chatWithProvider(context, ref, referral),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat about Referral'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryTeal,
                      elevation: 0,
                    ),
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
    if (s == 'completed' || s == 'accomplished') color = Colors.green;
    if (s == 'active' || s == 'pending') color = Colors.blue;
    if (s == 'expired' || s == 'cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _chatWithProvider(BuildContext context, WidgetRef ref, Referral referral) async {
     try {
       // Target ID could be targetDoctor user ID or targetStore owner ID
       // Mocking the connection for now
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting chat with provider...')));
       // Implementation would use referral.targetDoctor.userId or similar
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat started! (Demo Mode)')));
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     }
  }
}
