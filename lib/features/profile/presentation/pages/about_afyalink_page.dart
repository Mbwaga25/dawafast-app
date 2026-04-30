import 'package:flutter/material.dart';
import 'package:afyalink/core/theme.dart';

class AboutAfyalinkPage extends StatelessWidget {
  const AboutAfyalinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About AfyaLink'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              color: AppTheme.primaryTeal.withValues(alpha: 0.05),
              child: Column(
                children: [
                  const Icon(Icons.favorite, size: 64, color: AppTheme.primaryTeal),
                  const SizedBox(height: 16),
                  const Text(
                    'AfyaLink',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Mission',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AfyaLink is devoted to connecting you seamlessly with the best healthcare providers, pharmacies, and specialists. Our mission is to democratize healthcare access by bringing virtual consultations, medical deliveries, and smart records management directly to your fingertips.',
                    style: TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Core Services',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildServiceItem(Icons.local_pharmacy_outlined, 'Vast Pharmacy Network'),
                  _buildServiceItem(Icons.videocam_outlined, 'Instant Telemedicine Call'),
                  _buildServiceItem(Icons.vaccines_outlined, 'Digital Lab Records'),
                  _buildServiceItem(Icons.badge_outlined, 'Specialist Referrals'),
                  
                  const SizedBox(height: 48),
                  const Center(
                    child: Text(
                      '© 2024 AfyaLink. All rights reserved.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentTeal),
          ),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
