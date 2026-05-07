import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';

class HospitalCreatePage extends ConsumerStatefulWidget {
  const HospitalCreatePage({super.key});

  @override
  ConsumerState<HospitalCreatePage> createState() => _HospitalCreatePageState();
}

class _HospitalCreatePageState extends ConsumerState<HospitalCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedType = 'HOSPITAL';
  bool _isLoading = false;
  final _locationService = LocationService();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      // Attempt to get current location
      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (e) {
        debugPrint('Location service error: $e');
      }

      final repo = ref.read(healthcareRepositoryProvider);
      final result = await repo.createStore(
        name: _nameController.text,
        storeType: _selectedType,
        address: _addressController.text,
        latitude: position?.latitude ?? -6.7924, // Fallback to DSM
        longitude: position?.longitude ?? 39.2083,
        description: _descController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facility registered successfully!')),
        );
        Navigator.pop(context);
        ref.invalidate(hospitalsProvider((type: null, search: null)));
      } else {
        final errors = (result['errors'] as List?)?.join(', ') ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Medical Facility')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Facility Name', prefixIcon: Icon(Icons.business)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Facility Type', prefixIcon: Icon(Icons.category)),
                items: ['HOSPITAL', 'PHARMACY', 'LAB', 'CLINIC']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 32),
              const Text('Contact & Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Full Address', prefixIcon: Icon(Icons.location_on)),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final address = await _locationService.getAddressFromCurrentPosition();
                      setState(() => _isLoading = false);
                      if (address != null) {
                        _addressController.text = address;
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not resolve address')),
                          );
                        }
                      }
                    },
                    tooltip: 'Autofill from current location',
                    icon: const Icon(Icons.my_location, color: AppTheme.primaryTeal),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Business Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register Facility', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
