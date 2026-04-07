import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/core/services/location_service.dart';
import '../../../../core/theme.dart';
import 'package:app/features/healthcare/presentation/pages/hospital_detail_page.dart';
import '../../data/models/hospital_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HospitalCard extends ConsumerStatefulWidget {
  final Hospital hospital;

  const HospitalCard({super.key, required this.hospital});

  @override
  ConsumerState<HospitalCard> createState() => _HospitalCardState();
}

class _HospitalCardState extends ConsumerState<HospitalCard> {
  Position? _userPosition;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (mounted) setState(() => _userPosition = pos);
  }

  @override
  Widget build(BuildContext context) {
    String? distanceStr;
    String? timeStr;
    if (_userPosition != null && widget.hospital.latitude != null && widget.hospital.longitude != null) {
      final dist = _locationService.calculateDistance(_userPosition!.latitude, _userPosition!.longitude, widget.hospital.latitude!, widget.hospital.longitude!);
      distanceStr = '${dist.toStringAsFixed(1)} km';
      timeStr = _locationService.estimateTravelTime(dist);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HospitalDetailPage(idOrSlug: widget.hospital.slug),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'lib/assets/images/medical_placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hospital.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              widget.hospital.city ?? 'Dar es Salaam',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        if (distanceStr != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.near_me, size: 14, color: AppTheme.accentTeal),
                              const SizedBox(width: 4),
                              Text(
                                '$distanceStr • $timeStr',
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Open 24/7',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.borderColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text('4.5', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(120 reviews)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
