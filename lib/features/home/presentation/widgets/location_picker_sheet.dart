import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/providers/location_provider.dart';

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final _searchController = TextEditingController();
  bool _isLocating = false;

  final List<String> _recentLocations = [
    'Dar es Salaam City Center',
    'Masaki, Dar es Salaam',
    'Mikocheni, Dar es Salaam',
    'Sinza, Dar es Salaam',
  ];

  List<String> _searchResults = [];
  String? _detectedAddress;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _detectedAddress = null;
    });
    try {
      final position = await LocationService().getCurrentPosition();
      if (position != null) {
        // Mock reverse geocoding
        // In reality, this would call a Geocoding API
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _detectedAddress = 'Sinza Mori, Dar es Salaam';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get your location. Please check permissions.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      // Mock search results
      _searchResults = _recentLocations
          .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      if (_searchResults.isEmpty) {
        _searchResults = [
          '$query, Dar es Salaam',
          'Street results for $query...',
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Delivery Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search area, street or landmark',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(selectedLocationProvider.notifier).state = value.trim();
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          if (_detectedAddress != null) ...[
            // Confirmation View
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.primaryTeal, size: 20),
                      SizedBox(width: 8),
                      Text('Location Detected', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_detectedAddress!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _detectedAddress = null),
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(selectedLocationProvider.notifier).state = _detectedAddress!;
                            Navigator.pop(context);
                          },
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else if (_isSearching) ...[
            // Search Results
            const Text(
              'Search Results',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ..._searchResults.map((loc) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryTeal),
              title: Text(loc, style: const TextStyle(fontSize: 14)),
              onTap: () {
                ref.read(selectedLocationProvider.notifier).state = loc;
                Navigator.pop(context);
              },
            )),
          ] else ...[
          // Current Location Button
          InkWell(
            onTap: _isLocating ? null : _useCurrentLocation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _isLocating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: AppTheme.primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Current Location',
                        style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Using GPS to find your location',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 32),
          
          const Text(
            'Recent Locations',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          
          ..._recentLocations.map((loc) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: AppTheme.textSecondary),
            title: Text(loc, style: const TextStyle(fontSize: 14)),
            onTap: () {
              ref.read(selectedLocationProvider.notifier).state = loc;
              Navigator.pop(context);
            },
          )),
          
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
}
}
