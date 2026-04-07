import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/models/doctor_model.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/healthcare/data/repositories/healthcare_repository.dart';

class ReferralWizard extends ConsumerStatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? appointmentId;

  const ReferralWizard({
    super.key,
    this.patientId, 
    this.patientName, 
    this.appointmentId
  });

  @override
  ConsumerState<ReferralWizard> createState() => _ReferralWizardState();
}

class _ReferralWizardState extends ConsumerState<ReferralWizard> {
  int _currentStep = 1;
  String? _selectedType; // 'LAB', 'PHARMACY', 'HOSPITAL', 'DOCTOR'
  HospitalShort? _selectedFacility;
  Doctor? _selectedDoctor;
  
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();
  final _diagnosticNotesController = TextEditingController();
  
  List<String> _selectedLabTestIds = [];
  List<String> _selectedProductIds = [];
  List<Map<String, dynamic>> _customItems = []; // For labels

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    _diagnosticNotesController.dispose();
    super.dispose();
  }

  Future<void> _dispatchReferral() async {
    try {
      final success = await ref.read(doctorsRepositoryProvider).referPatient(
        patientId: widget.patientId!,
        providerType: _selectedType!,
        providerId: _selectedType == 'DOCTOR' ? _selectedDoctor!.id : _selectedFacility!.id,
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : "Referral for ${_selectedType}",
        notes: _diagnosticNotesController.text.isNotEmpty 
          ? "DIAGNOSTIC: ${_diagnosticNotesController.text}\nITEMS: ${_customItems.map((e) => e['name']).join(', ')}"
          : _customItems.map((e) => e['name']).join(', '),
        labTestIds: _selectedLabTestIds,
        productIds: _selectedProductIds,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral sent successfully!'), backgroundColor: Colors.green));
        ref.invalidate(sentReferralsProvider(null));
      } else {
        throw 'Failed to send referral';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 32),
          Expanded(child: _buildStepContent()),
          const SizedBox(height: 16),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = "Transfer Patient";
    if (_currentStep == 1) title = "Where to Transfer?";
    if (_currentStep == 2) title = "Select Facility";
    if (_currentStep == 3) title = _getStep3Title();
    if (_currentStep == 4) title = "Confirm Referral";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Patient: ${widget.patientName ?? "Unknown"}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  String _getStep3Title() {
    switch (_selectedType) {
      case 'PHARMACY': return 'Prescribe Medicines';
      case 'LAB': return 'Order Health Services';
      case 'HOSPITAL': return 'Describe Medical Issue';
      case 'DOCTOR': return 'Referral Details';
      default: return 'Specification';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() {
    final options = [
      {'label': 'Laboratory', 'type': 'LAB', 'icon': Icons.biotech, 'color': Colors.blue},
      {'label': 'Pharmacy', 'type': 'PHARMACY', 'icon': Icons.medication, 'color': Colors.teal},
      {'label': 'Hospital', 'type': 'HOSPITAL', 'icon': Icons.local_hospital, 'color': Colors.red},
      {'label': 'Specialist', 'type': 'DOCTOR', 'icon': Icons.person_search, 'color': Colors.purple},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: options.length,
      itemBuilder: (context, i) {
        final opt = options[i];
        bool isSelected = _selectedType == opt['type'];
        return InkWell(
          onTap: () => setState(() {
            _selectedType = opt['type'] as String;
            _currentStep = 2;
          }),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? (opt['color'] as Color).withOpacity(0.1) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? opt['color'] as Color : Colors.transparent, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(opt['icon'] as IconData, size: 48, color: opt['color'] as Color),
                const SizedBox(height: 12),
                Text(opt['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2() {
    if (_selectedType == 'DOCTOR') {
      final doctorsAsync = ref.watch(doctorsProvider((specialty: null, search: _searchController.text)));
      return Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Search specialists...', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) => ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, i) {
                  final doc = doctors[i];
                  if (doc.id == widget.patientId) return const SizedBox(); // Don't refer to self
                  bool isSelected = _selectedDoctor?.id == doc.id;
                  return ListTile(
                    leading: CircleAvatar(child: Text(doc.user.lastName?[0] ?? 'D')),
                    title: Text('Dr. ${doc.user.firstName} ${doc.user.lastName}'),
                    subtitle: Text(doc.specialty ?? 'General'),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.purple) : null,
                    onTap: () => setState(() => _selectedDoctor = doc),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ],
      );
    } else {
      final facilitiesAsync = ref.watch(hospitalsProvider((type: _selectedType, search: null)));
      return Column(
        children: [
           TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'Search for $_selectedType...', prefixIcon: const Icon(Icons.search)),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: facilitiesAsync.when(
              data: (facilities) {
                final filtered = facilities.where((f) => f.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final fac = filtered[i];
                    bool isSelected = _selectedFacility?.id == fac.id;
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.primaryTeal),
                      title: Text(fac.name),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryTeal) : null,
                      onTap: () => setState(() => _selectedFacility = HospitalShort(
                        id: fac.id,
                        name: fac.name,
                        slug: fac.slug,
                        city: fac.city,
                      )),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStep3() {
    if (_selectedType == 'DOCTOR' || _selectedType == 'HOSPITAL') {
      return Column(
        children: [
          const Text('Provide clinical notes and reason for transfer', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Describe the issue, clinical findings, and why the transfer is necessary...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
    } else if (_selectedType == 'PHARMACY') {
       if (_selectedFacility == null) return const Center(child: Text('Please select a pharmacy first.'));
       final detailAsync = ref.watch(hospitalDetailProvider(_selectedFacility!.id));
       return Column(
         children: [
             TextField(
               controller: _diagnosticNotesController,
               maxLines: 3,
               decoration: const InputDecoration(
                 hintText: 'Diagnostic notes for the pharmacist (e.g. Dosage, duration)...',
                 border: OutlineInputBorder(),
               ),
             ),
             const SizedBox(height: 16),
             TextField(
               controller: _searchController,
               decoration: const InputDecoration(hintText: 'Search medicines in this pharmacy...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: detailAsync.when(
                data: (fac) {
                  final products = fac?.products ?? [];
                  final filtered = products.where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                  if (filtered.isEmpty) return const Center(child: Text('No matching medicines found.'));
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      bool isSelected = _selectedProductIds.contains(p.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(p.name),
                        subtitle: Text('TZS ${p.price}'),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedProductIds.add(p.id);
                              _customItems.add({'id': p.id, 'name': p.name});
                            } else {
                              _selectedProductIds.remove(p.id);
                              _customItems.removeWhere((x) => x['id'] == p.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading inventory: $e'),
              ),
            ),
         ],
       );
    } else if (_selectedType == 'LAB') {
       if (_selectedFacility == null) return const Center(child: Text('Please select a laboratory first.'));
       final detailAsync = ref.watch(hospitalDetailProvider(_selectedFacility!.id));
       return Column(
         children: [
            TextField(
              controller: _diagnosticNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Clinical diagnostic notes/instructions for the laboratory...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select tests to be performed', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
           Expanded(
             child: detailAsync.when(
                data: (fac) {
                  final tests = fac?.labTests ?? [];
                  if (tests.isEmpty) return const Center(child: Text('No health services available at this facility.'));
                  return ListView.builder(
                    itemCount: tests.length,
                    itemBuilder: (context, i) {
                      final t = tests[i];
                      bool isSelected = _selectedLabTestIds.contains(t.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(t.name),
                        subtitle: Text('Price: TZS ${t.price} • TAT: ${t.turnaroundTime}'),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedLabTestIds.add(t.id);
                              _customItems.add({'id': t.id, 'name': t.name});
                            } else {
                              _selectedLabTestIds.remove(t.id);
                              _customItems.removeWhere((x) => x['id'] == t.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading tests: $e'),
             ),
           )
         ],
       );
    }
    return const SizedBox();
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Target Type', _selectedType ?? 'N/A'),
          _buildSummaryRow('Facility/Doctor', _selectedType == 'DOCTOR' ? 'Dr. ${_selectedDoctor?.user.lastName}' : (_selectedFacility?.name ?? 'N/A')),
          const SizedBox(height: 16),
          const Text('Reason/Diagnoses:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(_reasonController.text.isEmpty && _diagnosticNotesController.text.isEmpty 
            ? 'No clinical notes provided.' 
            : (_reasonController.text.isNotEmpty ? _reasonController.text : _diagnosticNotesController.text)),
          const SizedBox(height: 16),
          const Text('Items/Tests:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_customItems.isEmpty) const Text('No specific items selected.')
          else ..._customItems.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4),
            child: Row(children: [const Icon(Icons.check, size: 14, color: Colors.green), const SizedBox(width: 8), Text(item['name'])]),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () {
               if (_currentStep == 1 && _selectedType == null) return;
               if (_currentStep == 2 && (_selectedFacility == null && _selectedDoctor == null)) return;
               if (_currentStep == 3) {
                  setState(() => _currentStep = 4);
                  return;
               }
               if (_currentStep == 4) {
                  _dispatchReferral();
                  return;
               }
               setState(() => _currentStep++);
            },
            child: Text(_currentStep == 4 ? 'Confirm & Send' : 'Continue', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
