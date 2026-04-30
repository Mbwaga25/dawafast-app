import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/auth/data/models/user_model.dart';
import 'package:afyalink/features/appointments/data/models/appointment_model.dart';
import 'package:afyalink/features/orders/data/models/order_model.dart';
import 'package:afyalink/features/home/presentation/widgets/dashboards/pharmacy_chat_page.dart';
import 'package:afyalink/features/auth/data/repositories/auth_repository.dart';
import 'package:afyalink/features/auth/data/repositories/user_repository.dart';
import 'package:afyalink/features/healthcare/data/repositories/pharmacy_repository.dart';
import 'package:afyalink/features/orders/data/repositories/order_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io' as io;

// --- Local State Notifiers for UI Refresh ---

final pharmacyOrdersProvider = FutureProvider.family<List<Order>, String>((ref, storeId) async {
  return ref.watch(orderRepositoryProvider).fetchMyOrders(); 
});

final pharmacyReferralsProvider = FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  return ref.watch(pharmacyRepositoryProvider).getPrescriptions(storeId);
});

final pharmacySentReferralsProvider = FutureProvider.family<List<dynamic>, String>((ref, userId) async {
  return ref.watch(pharmacyRepositoryProvider).getSentReferrals();
});

final pharmacyInventoryProvider = FutureProvider.family<List<dynamic>, String>((ref, storeId) async {
  return ref.watch(pharmacyRepositoryProvider).getStoreProducts(storeId);
});

final pharmacyReportProvider = FutureProvider.family<PharmacyReport, String>((ref, userId) async {
  return ref.watch(pharmacyRepositoryProvider).getPharmacyReport(userId);
});

// --- Main Pharmacy Dashboard ---

class PharmacyDashboard extends ConsumerStatefulWidget {
  final User user;
  const PharmacyDashboard({super.key, required this.user});

  @override
  ConsumerState<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends ConsumerState<PharmacyDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _OverviewTab(user: widget.user),
      _OrdersTab(user: widget.user),
      _InventoryTab(user: widget.user),
      _ReportsTab(user: widget.user),
      _ProfileTab(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryTeal,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.store_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// --- 1. Overview Tab ---
class _OverviewTab extends ConsumerWidget {
  final User user;
  const _OverviewTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(pharmacyReportProvider(user.id.toString()));
    final currencyAsync = ref.watch(activeCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline), 
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyChatPage()));
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pharmacyReportProvider(user.id.toString()).future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              const SizedBox(height: 24),
              reportAsync.when(
                data: (report) => _buildStatsGrid(context, report, currencyAsync.value?.symbol ?? '/='),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                   _buildQuickAction(context, 'New Referral', Icons.medical_services, Colors.purple, () => _showReferralDialog(context)),
                   const SizedBox(width: 16),
                   _buildQuickAction(context, 'Add Stock', Icons.add_box, Colors.blue, () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferralDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReferralWizardSheet(),
    );
  }

  Widget _buildHeader(User user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
          child: const Icon(Icons.store, color: AppTheme.primaryTeal),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: AppTheme.headingStyle.copyWith(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey)),
            Text(user.username, style: AppTheme.headingStyle.copyWith(fontSize: 18)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, PharmacyReport report, String currency) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Pending', '${report.pendingCount}', Icons.hourglass_empty, Colors.orange),
        _buildStatCard('Delivered', '${report.accomplishedCount}', Icons.check_circle, Colors.green),
        _buildStatCard('Revenue', '$currency${report.totalRevenue.toStringAsFixed(0)}', Icons.payments, AppTheme.primaryTeal),
        _buildStatCard('Missed', '${report.missedCount}', Icons.cancel, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.05), border: Border.all(color: color.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Icon(icon, color: color), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]),
        ),
      ),
    );
  }
}

// --- 2. Orders Tab ---

class _OrdersTab extends ConsumerWidget {
  final User user;
  const _OrdersTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders & Referrals'),
          bottom: const TabBar(
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryTeal,
            tabs: [Tab(text: 'Customer Orders'), Tab(text: 'Doctor Referrals')],
          ),
        ),
        body: TabBarView(
          children: [_DirectOrdersView(user: user), _ReferralsView(user: user)],
        ),
      ),
    );
  }
}

class _DirectOrdersView extends ConsumerStatefulWidget {
  final User user;
  const _DirectOrdersView({required this.user});

  @override
  ConsumerState<_DirectOrdersView> createState() => _DirectOrdersViewState();
}

class _DirectOrdersViewState extends ConsumerState<_DirectOrdersView> {
  String _selectedStatus = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(pharmacyOrdersProvider(widget.user.id.toString()));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusChip(
                  label: 'Pending',
                  isSelected: _selectedStatus == 'PENDING',
                  onTap: () => setState(() => _selectedStatus = 'PENDING'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Confirmed',
                  isSelected: _selectedStatus == 'CONFIRMED',
                  onTap: () => setState(() => _selectedStatus = 'CONFIRMED'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'History',
                  isSelected: _selectedStatus == 'DELIVERED',
                  onTap: () => setState(() => _selectedStatus = 'DELIVERED'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Rejected',
                  isSelected: _selectedStatus == 'CANCELLED',
                  onTap: () => setState(() => _selectedStatus = 'CANCELLED'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(pharmacyOrdersProvider(widget.user.id.toString()).future),
            child: ordersAsync.when(
              data: (orders) {
                final filtered = orders.where((o) {
                  final status = o.status.toUpperCase();
                  if (_selectedStatus == 'CONFIRMED') {
                    return status == 'CONFIRMED' || status == 'PROCESSING';
                  }
                  return status == _selectedStatus;
                }).toList();
                return filtered.isEmpty 
                  ? const Center(child: Text('No orders found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final order = filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${order.clientName} • ${DateFormat('HH:mm').format(order.orderDate)}'),
                            trailing: _buildStatusBadge(order.status),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    ...order.items.map((item) => ListTile(
                                      title: Text(item.productName),
                                      trailing: Text('x${item.quantity}'),
                                    )),
                                    const Divider(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _showReportDialog(ref, context, order.id),
                                              icon: const Icon(Icons.note_add_rounded, size: 16),
                                              label: const Text('Add Report'),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              onPressed: () => _updateStatus(ref, context, order.id, 'cancelled'),
                                              child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () => _updateStatus(ref, context, order.id, (order.status == 'Pending' ? 'processing' : 'delivered')),
                                              child: Text(order.status == 'Pending' ? 'Confirm' : 'Mark Delivered'),
                                            ),
                                          ],
                                        )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status.toLowerCase() == 'pending' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _updateStatus(WidgetRef ref, BuildContext context, String id, String status) async {
    try {
      final success = await ref.read(orderRepositoryProvider).updateOrderStatus(id, status);
      if (success) {
        ref.refresh(pharmacyOrdersProvider(widget.user.id.toString()));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $status')));
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showReportDialog(WidgetRef ref, BuildContext context, String orderId) {}
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
      checkmarkColor: AppTheme.primaryTeal,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryTeal : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _ReferralWizardSheet extends ConsumerStatefulWidget {
  @override
  _ReferralWizardSheetState createState() => _ReferralWizardSheetState();
}

class _ReferralWizardSheetState extends ConsumerState<_ReferralWizardSheet> {
  int _currentStep = 0;
  dynamic _selectedPatient;
  List<dynamic> _patientSearchResults = [];
  bool _isSearchingPatient = false;
  final TextEditingController _patientSearchController = TextEditingController();
  bool _isRegistrationMode = false;
  final _regFirstName = TextEditingController();
  final _regLastName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  String _providerType = 'DOCTOR';
  dynamic _selectedProvider;
  List<dynamic> _providerSearchResults = [];
  bool _isSearchingProvider = false;
  final TextEditingController _providerSearchController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  void _searchPatients(String query) async {
    if (query.length < 2) return;
    setState(() => _isSearchingPatient = true);
    try {
      final results = await ref.read(pharmacyRepositoryProvider).searchPatients(query);
      setState(() => _patientSearchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      setState(() => _isSearchingPatient = false);
    }
  }

  void _searchProviders(String query) async {
    setState(() => _isSearchingProvider = true);
    try {
      final repo = ref.read(pharmacyRepositoryProvider);
      if (_providerType == 'DOCTOR') {
        final results = await repo.searchDoctors(query);
        setState(() => _providerSearchResults = results);
      } else {
        final results = await repo.searchStores(_providerType, city: null);
        setState(() => _providerSearchResults = results.where((s) => s['name'].toString().toLowerCase().contains(query.toLowerCase())).toList());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      setState(() => _isSearchingProvider = false);
    }
  }

  Future<void> _submitReferral() async {
    if (_selectedPatient == null && !_isRegistrationMode) return;
    if (_selectedProvider == null) return;
    if (_reasonController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(pharmacyRepositoryProvider);
      String? pId;
      if (_isRegistrationMode) {
        final result = await repo.registerPatient(
          firstName: _regFirstName.text, 
          lastName: _regLastName.text, 
          email: _regEmail.text, 
          password: 'Password123!', 
          phone: _regPhone.text
        );
        pId = result.data?['patientProfile']?['id'];
        if (pId == null) throw 'Failed to retrieve patient profile after registration';
      } else {
        pId = _selectedPatient?['patientProfile']?['id'];
        if (pId == null) throw 'Selected user does not have a complete patient profile';
      }
      
      String patientId = pId!;
      String providerId = _selectedProvider['id'];

      final result = await repo.referPatient(
        patientId: patientId, 
        providerType: _providerType, 
        providerId: providerId, 
        reason: _reasonController.text, 
        notes: _notesController.text
      );
      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral submitted successfully'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${result['errors']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () => _currentStep < 2 ? setState(() => _currentStep++) : _submitReferral(),
              onStepCancel: () => _currentStep > 0 ? setState(() => _currentStep--) : Navigator.pop(context),
              steps: [
                Step(title: const Text('Patient'), content: _buildPatientStep()),
                Step(title: const Text('Provider'), content: _buildProviderStep()),
                Step(title: const Text('Reason'), content: _buildReasonStep()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStep() {
    return Column(
      children: [
        TextField(
          controller: _patientSearchController,
          onChanged: _searchPatients,
          decoration: InputDecoration(
            labelText: 'Search Patient',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearchingPatient ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: _patientSearchResults.isEmpty 
            ? const Center(child: Text('No patients found', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: _patientSearchResults.length,
                itemBuilder: (ctx, i) {
                  final patient = _patientSearchResults[i]['node'];
                  final fullName = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
                  final isSelected = _selectedPatient != null && _selectedPatient['id'] == patient['id'];
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppTheme.primaryTeal : Colors.grey[200],
                      child: Text(patient['firstName']?[0] ?? 'P', style: TextStyle(color: isSelected ? Colors.white : AppTheme.primaryTeal)),
                    ),
                    title: Text(fullName.isEmpty ? 'Unknown Patient' : fullName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(patient['email'] ?? 'No email'),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryTeal) : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedPatient = patient;
                        _currentStep = 1; // Auto advance to provider step
                      });
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildProviderStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'DOCTOR', label: Text('Doctor'), icon: Icon(Icons.person)),
                  ButtonSegment(value: 'HOSPITAL', label: Text('Hospital'), icon: Icon(Icons.local_hospital)),
                  ButtonSegment(value: 'LAB', label: Text('Lab'), icon: Icon(Icons.biotech)),
                ],
                selected: {_providerType},
                onSelectionChanged: (set) {
                   setState(() {
                     _providerType = set.first;
                     _selectedProvider = null;
                     _providerSearchResults = [];
                     _providerSearchController.clear();
                   });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _providerSearchController,
          onChanged: _searchProviders,
          decoration: InputDecoration(
            labelText: 'Search provider...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearchingProvider ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: _providerSearchResults.isEmpty 
            ? const Center(child: Text('Search for a doctor or facility', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: _providerSearchResults.length,
                itemBuilder: (ctx, i) {
                  final p = _providerSearchResults[i];
                  String name = '';
                  String sub = '';
                  String id = '';
                  
                  if (_providerType == 'DOCTOR') {
                    final user = p['user'];
                    name = 'Dr. ${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();
                    if (name == 'Dr.') name = 'Dr. ${user?['username'] ?? 'Specialist'}';
                    sub = p['specialty'] ?? 'General Physician';
                    id = p['id'];
                  } else {
                    name = p['name'] ?? 'Provider';
                    sub = p['city'] ?? 'Facility';
                    id = p['id'];
                  }
                  
                  final isSelected = _selectedProvider != null && _selectedProvider['id'] == p['id'];

                  return ListTile(
                    leading: Icon(_providerType == 'DOCTOR' ? Icons.person : Icons.location_on, color: isSelected ? AppTheme.primaryTeal : Colors.grey),
                    title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(sub),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryTeal) : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedProvider = p;
                        _currentStep = 2; // Auto advance to reason step
                      });
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildReasonStep() => Column(children: [TextField(controller: _reasonController, decoration: const InputDecoration(labelText: 'Reason')), TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes'))]);
}

class _ReferralsView extends ConsumerStatefulWidget {
  final User user;
  const _ReferralsView({required this.user});

  @override
  ConsumerState<_ReferralsView> createState() => _ReferralsViewState();
}

class _ReferralsViewState extends ConsumerState<_ReferralsView> {
  String _selectedSection = 'RECEIVED';

  @override
  Widget build(BuildContext context) {
    final referralsAsync = _selectedSection == 'RECEIVED' 
        ? ref.watch(pharmacyReferralsProvider(widget.user.id.toString()))
        : ref.watch(pharmacySentReferralsProvider(widget.user.id.toString()));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'RECEIVED', label: Text('Incoming'), icon: Icon(Icons.download_rounded)),
              ButtonSegment(value: 'SENT', label: Text('Sent'), icon: Icon(Icons.upload_rounded)),
            ],
            selected: {_selectedSection},
            onSelectionChanged: (set) => setState(() => _selectedSection = set.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
              selectedForegroundColor: AppTheme.primaryTeal,
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
               if (_selectedSection == 'RECEIVED') ref.refresh(pharmacyReferralsProvider(widget.user.id.toString()).future);
               else ref.refresh(pharmacySentReferralsProvider(widget.user.id.toString()).future);
            },
            child: referralsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(child: Text(_selectedSection == 'RECEIVED' ? 'No incoming prescriptions' : 'No clinical transfers sent'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final item = list[i];
                    if (_selectedSection == 'RECEIVED') return _buildIncomingCard(item);
                    return _buildOutgoingCard(item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingCard(dynamic presc) {
    final consultation = presc['consultation'];
    final patient = consultation['patient'];
    final doctor = consultation['doctor']['user'];
    final items = (presc['items'] as List<dynamic>);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('${patient['firstName']} ${patient['lastName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: #${presc['id']} • From: Dr. ${doctor['firstName']}'),
        leading: CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.1), child: const Icon(Icons.person, color: Colors.blue)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (presc['notes'] != null) ...[
                  const Text('Doctor Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(presc['notes'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                const Text('Prescribed Medicines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ...items.map((m) => ListTile(
                  dense: true,
                  title: Text(m['medicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${m['dosage']} - ${m['duration']}'),
                )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showDispenseDialog(context, presc),
                      child: const Text('Dispense'),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOutgoingCard(dynamic referral) {
    final patient = referral['patient']['user'];
    final providerType = referral['providerType'];
    String targetName = '';
    if (providerType == 'doctor') {
      targetName = 'Dr. ${referral['targetDoctor']['user']['firstName']}';
    } else {
      targetName = referral['targetStore']?['name'] ?? 'Provider';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.orange.withValues(alpha: 0.1), child: const Icon(Icons.outbox, color: Colors.orange)),
        title: Text('${patient['firstName']} ${patient['lastName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('To: $targetName • ${referral['reason']}'),
        trailing: _buildStatusChip(referral['status']),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showDispenseDialog(BuildContext context, dynamic presc) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispense Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Marking prescription #${presc['id']} as filled.'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Dispensing Notes', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await ref.read(pharmacyRepositoryProvider).dispensePrescription(presc['id'], notesController.text);
                if (result.success) {
                  Navigator.pop(ctx);
                  ref.refresh(pharmacyReferralsProvider(widget.user.id.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription filled successfully'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result.message}'), backgroundColor: Colors.red));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Mark as Filled'),
          ),
        ],
      ),
    );
  }
}

// --- 3. Inventory Tab ---
class _InventoryTab extends ConsumerStatefulWidget {
  final User user;
  const _InventoryTab({required this.user});

  @override
  ConsumerState<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<_InventoryTab> {
  String _searchQuery = '';
  List<dynamic> _searchResults = [];
  bool _isSearching = false; // Default to false

  void _onSearch(String val) async {
    setState(() { _searchQuery = val; _isSearching = true; });
    if (val.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    try {
      final results = await ref.read(pharmacyRepositoryProvider).searchProducts(val);
      setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      setState(() { _isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded), 
            onPressed: () => _showAddProductOptions(context),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search global products to clone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          Expanded(
            child: _searchQuery.isNotEmpty 
              ? ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final p = _searchResults[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: p['image'] != null && p['image']['imageUrl'] != null
                            ? Image.network(p['image']['imageUrl'], width: 50, height: 50, errorBuilder: (c, e, s) => const Icon(Icons.medication))
                            : const Icon(Icons.medication),
                        title: Text(p['name']),
                        subtitle: Text('Brand: ${p['brand'] ?? 'Generic'} • Price: ${p['price']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _showCloneWizard(context, p),
                          child: const Text('Clone'),
                        ),
                      ),
                    );
                  },
                )
              : _buildMyProductsList(),
          ),
        ],
      ),
    );
  }

  void _showAddProductOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Add Product to Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.search, color: AppTheme.primaryTeal),
            title: const Text('Clone from Global Catalog'),
            subtitle: const Text('Search thousands of approved products'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() { _isSearching = true; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use search bar above to find products to clone')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined, color: AppTheme.primaryTeal),
            title: const Text('Submit New Product'),
            subtitle: const Text('Suggest a new item to administrators'),
            onTap: () {
              Navigator.pop(ctx);
              _showSubmitProductForm(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMyProductsList() {
    final inventoryAsync = ref.watch(pharmacyInventoryProvider(widget.user.id.toString()));
    return inventoryAsync.when(
      data: (items) => items.isEmpty 
        ? const Center(child: Text('No products in your store. Search above to add some!'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final product = item['product'];
              return _buildInventoryItem(
                id: item['id'],
                productId: product['id'],
                name: product['name'],
                price: item['price'].toString(),
                available: item['isAvailable'],
                quantity: item['quantity'] ?? 0,
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildInventoryItem({
    required String id, 
    required String productId,
    required String name, 
    required String price, 
    required bool available, 
    required int quantity
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name),
        subtitle: Text('Price: /= $price • Stock: $quantity'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal),
              onPressed: () => _showUpdateStockDialog(context, productId, name, price, quantity),
            ),
            Switch(
              value: available,
              onChanged: (val) async {
                final result = await ref.read(pharmacyRepositoryProvider).toggleAvailability(id, val);
                if (result.success) {
                  ref.invalidate(pharmacyInventoryProvider(widget.user.id.toString()));
                } else if (result.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
                }
              },
              activeColor: AppTheme.primaryTeal,
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, String id, String name, String currentPrice, int currentQuantity) {
    final priceController = TextEditingController(text: currentPrice);
    final stockController = TextEditingController(text: currentQuantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(pharmacyRepositoryProvider).updateStock(
                storeId: widget.user.id.toString(),
                productId: id,
                stock: int.parse(stockController.text),
                price: double.parse(priceController.text),
              );
              if (result.success) {
                Navigator.pop(ctx);
                ref.invalidate(pharmacyInventoryProvider(widget.user.id.toString()));
              } else if (result.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCloneWizard(BuildContext context, dynamic product) {
    final priceController = TextEditingController(text: product['price'].toString());
    final stockController = TextEditingController(text: '10');
    final variants = (product['variants'] as List<dynamic>?) ?? [];
    String? selectedVariantId = variants.isNotEmpty ? variants[0]['id'] : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clone: ${product['name']}', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              if (variants.isNotEmpty) ...[
                const Text('Select Variation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedVariantId,
                  items: variants.map((v) => DropdownMenuItem<String>(
                    value: v['id'],
                    child: Text('${v['name']} (${v['price']})'),
                  )).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedVariantId = val;
                      final selected = variants.firstWhere((v) => v['id'] == val);
                      priceController.text = selected['price'].toString();
                    });
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Your Price', prefixText: '/= '), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await ref.read(pharmacyRepositoryProvider).cloneProduct(
                      storeId: widget.user.id.toString(),
                      productId: product['id'],
                      variantId: selectedVariantId,
                      price: double.parse(priceController.text),
                      stock: int.parse(stockController.text),
                    );
                    if (result.success) {
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      setState(() {
                        _searchQuery = "";
                        _searchResults = [];
                      });
                      ref.invalidate(pharmacyInventoryProvider(widget.user.id.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product cloned successfully')));
                    } else if (result.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Clone to Store'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitProductForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubmitProductSheet(storeId: widget.user.id.toString()),
    );
  }
}

// --- New Feature Components ---

class _SubmitProductSheet extends ConsumerStatefulWidget {
  final String storeId;
  const _SubmitProductSheet({required this.storeId});
  @override
  ConsumerState<_SubmitProductSheet> createState() => _SubmitProductSheetState();
}

class _SubmitProductSheetState extends ConsumerState<_SubmitProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _skuController = TextEditingController();
  
  String? _categoryId;
  String? _brandId;
  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  bool _isLoadingLists = true;

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    try {
      final cats = await ref.read(pharmacyRepositoryProvider).getCategories();
      final brs = await ref.read(pharmacyRepositoryProvider).getBrands();
      setState(() {
        _categories = cats;
        _brands = brs;
        _isLoadingLists = false;
      });
    } catch (e) {
      setState(() => _isLoadingLists = false);
    }
  }

  String? _imagePath;
  String? _imageBase64;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imagePath = image.path;
        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Clinical Product Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
              const Text('Submit detailed product info for administrative review', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              
              _buildFieldTitle('Product Visual'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: _imagePath != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(io.File(_imagePath!), fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: AppTheme.primaryTeal), Text('Upload Product Photo')]),
                ),
              ),
              const SizedBox(height: 20),

              _buildFieldTitle('Basic Information'),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Scientific/Product Name', hintText: 'e.g. Paracetamol BP 500mg')),
              const SizedBox(height: 12),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Clinical Description/Indications'), maxLines: 3),
              const SizedBox(height: 20),
              _buildFieldTitle('Categorization'),
              if (_isLoadingLists) 
                const LinearProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoryId,
                        items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                        decoration: const InputDecoration(labelText: 'Category'),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _brandId,
                        items: _brands.map((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name']))).toList(),
                        onChanged: (v) => setState(() => _brandId = v),
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildFieldTitle('Pricing & Logistics'),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _skuController, decoration: const InputDecoration(labelText: 'Internal SKU'))),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await ref.read(pharmacyRepositoryProvider).submitProductToAdmin(
                      name: _nameController.text,
                      description: _descController.text,
                      price: double.tryParse(_priceController.text) ?? 100.0,
                      categoryId: _categoryId,
                      imageBase64: _imageBase64,
                    );
                    if (result.success) {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product submitted for clinical review')));
                    } else if (result.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Submit to Admin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal)));
  }

  Widget _buildDropdown(String label, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}

class _ReferToDoctorSheet extends ConsumerStatefulWidget {
  final String patientId;
  const _ReferToDoctorSheet({required this.patientId});
  @override
  ConsumerState<_ReferToDoctorSheet> createState() => _ReferToDoctorSheetState();
}

class _ReferToDoctorSheetState extends ConsumerState<_ReferToDoctorSheet> {
  String _search = '';
  List<dynamic> _doctors = [];
  bool _loading = false;
  bool _isSensitive = false;

  void _onSearch(String val) async {
    if (val.length < 2) return;
    setState(() => _loading = true);
    final results = await ref.read(pharmacyRepositoryProvider).searchDoctors(val);
    setState(() { _doctors = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Refer Case to Doctor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Transfer sensitive issues for expert clinical evaluation', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mark as Sensitive Case', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: const Text('Flag for immediate priority doctor review'),
            value: _isSensitive,
            onChanged: (val) => setState(() => _isSensitive = val),
            activeColor: Colors.red,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search specialists...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (ctx, i) {
                final d = _doctors[i]['node'];
                final profile = d['doctorProfile'];
                final user = profile['user'];
                return ListTile(
                  title: Text('Dr. ${user['firstName']} ${user['lastName']}'),
                  subtitle: Text(profile['specialization'] ?? 'General Physician'),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmReferral(d['id']),
                    child: const Text('Refer'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReferral(String doctorId) async {
    // Show reason dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Referral Reason'),
        content: const TextField(decoration: InputDecoration(hintText: 'e.g., Clinical evaluation required')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'Clinical consult required'), child: const Text('Confirm')),
        ],
      ),
    );

    if (reason != null) {
      final result = await ref.read(pharmacyRepositoryProvider).referPatient(
        patientId: widget.patientId,
        providerType: 'DOCTOR',
        providerId: doctorId,
        reason: reason,
      );
      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient referred successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${result['errors']}'), backgroundColor: Colors.red));
      }
    }
  }
}

// --- 4. Reports Tab ---
class _ReportsTab extends ConsumerWidget {
  final User user;
  const _ReportsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(pharmacyReportProvider(user.id.toString()));
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Reports')),
      body: reportAsync.when(
        data: (report) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildReportCard(context, 'Pending', '${report.pendingCount}', Colors.orange, report.pendingItems),
            _buildReportCard(context, 'Delivered', '${report.accomplishedCount}', Colors.green, report.accomplishedItems),
            _buildReportCard(context, 'Transferred', '${report.transferredCount}', Colors.blue, report.transferredItems),
            _buildReportCard(context, 'Cancelled', '${report.missedCount}', Colors.red, report.missedItems),
            const Divider(height: 40),
            Text('Financials', style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Live Revenue'),
                trailing: Text('TZS ${report.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryTeal)),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String label, String value, Color color, List<dynamic> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.list_alt, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showDrillDown(context, label, items),
              child: const Text('View List'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrillDown(BuildContext context, String title, List<dynamic> items) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: AppTheme.headingStyle.copyWith(fontSize: 18)),
            const Divider(),
            Expanded(
              child: items.isEmpty 
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text('Order #${item['id']}'),
                        subtitle: Text(item['clientName'] ?? 'Unknown'),
                        trailing: Text('${item['totalAmount']}'),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  final User user;
  const _ProfileTab({required this.user});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _bioController = TextEditingController(text: 'Trusted community pharmacy providing high-quality medications.');
  bool _isSmart = true;
  String _hours = '08:00 - 22:00';
  String? _imagePath;
  String? _imageBase64;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imagePath = image.path;
        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          const Text('Profile Bio', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
          const SizedBox(height: 8),
          TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Tell customers about your store...')),
          const SizedBox(height: 24),
          _buildSettingsTile(Icons.auto_awesome, 'Smart Pharmacy Status', 'Automated ordering & 24/7 priority', trailing: Switch(value: _isSmart, onChanged: (v) => setState(() => _isSmart = v), activeColor: AppTheme.primaryTeal)),
          _buildSettingsTile(Icons.access_time_rounded, 'Operating Hours', 'Current: $_hours', onTap: _editHours),
          _buildSettingsTile(Icons.lock_reset_rounded, 'Change Password', 'Update your account security', onTap: _changePassword),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(pharmacyRepositoryProvider).updateProfile(
                widget.user.id.toString(),
                description: _bioController.text,
                isSmart: _isSmart,
                imageBase64: _imageBase64,
              );
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
              } else if (result.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Save Profile Changes'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.invalidate(currentUserProvider);
            }, 
            child: const Text('Logout', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50, 
                backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1), 
                backgroundImage: _imagePath != null ? FileImage(io.File(_imagePath!)) : null,
                child: _imagePath == null ? const Icon(Icons.store, size: 40, color: AppTheme.primaryTeal) : null,
              ),
              Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 16, backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.camera_alt, size: 14), onPressed: _pickImage))),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.user.username, style: AppTheme.headingStyle.copyWith(fontSize: 22)),
          const Text('Verified Pharmacy Partner', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  void _editHours() {
    final controller = TextEditingController(text: _hours);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Hours'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. 24 Hours or 09:00-18:00')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { setState(() => _hours = controller.text); Navigator.pop(ctx); }, child: const Text('Update')),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'New Password')),
            SizedBox(height: 12),
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Update Security')),
        ],
      ),
    );
  }
}
