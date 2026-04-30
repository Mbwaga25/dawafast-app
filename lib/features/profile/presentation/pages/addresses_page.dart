import 'package:flutter/material.dart';
import 'package:afyalink/core/theme.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Addresses'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAddressCard(
            title: 'Home',
            address: '123 Main Street, Dar es Salaam, Tanzania',
            isDefault: true,
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 16),
          _buildAddressCard(
            title: 'Work',
            address: '456 Business Ave, Dar es Salaam, Tanzania',
            isDefault: false,
            icon: Icons.work_outline,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Address feature coming soon!')),
          );
        },
        backgroundColor: AppTheme.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Address', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required String address,
    required bool isDefault,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDefault ? AppTheme.primaryTeal : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDefault ? AppTheme.primaryTeal.withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDefault ? AppTheme.primaryTeal : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(address, style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
