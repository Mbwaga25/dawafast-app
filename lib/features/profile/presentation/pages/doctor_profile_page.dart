import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/profile/data/repositories/cv_repository.dart';
import 'package:app/features/profile/data/repositories/availability_repository.dart';
import 'package:intl/intl.dart';

class DoctorProfilePage extends ConsumerStatefulWidget {
  final User user;
  const DoctorProfilePage({super.key, required this.user});

  @override
  ConsumerState<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends ConsumerState<DoctorProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cvDataAsync = ref.watch(myCVDataProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppTheme.primaryTeal,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.primaryTeal, Color(0xFF1E3A8A)],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                '${widget.user.firstName?[0] ?? ''}${widget.user.lastName?[0] ?? ''}',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dr. ${widget.user.fullName}',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.user.doctorProfile?.specialty ?? 'General Practitioner',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.primaryTeal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryTeal,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Availability'),
                    Tab(text: 'Education'),
                    Tab(text: 'Experience'),
                    Tab(text: 'Skills'),
                    Tab(text: 'Certifications'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: cvDataAsync.when(
          data: (data) => TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(data),
              _buildAvailabilityTab(),
              _buildEducationTab(data['myEducation'] ?? []),
              _buildExperienceTab(data['myWorkExperiences'] ?? []),
              _buildSkillsTab(data['mySkills'] ?? []),
              _buildCertificationsTab(data['myCertifications'] ?? []),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading profile: $e')),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data) {
    final profile = data['myProfessionalProfile'] ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'About Me',
          icon: Icons.person_outline,
          content: Text(
            profile['bio'] ?? 'No bio provided yet.',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          onEdit: () => _editBio(profile['bio']),
        ),
        const SizedBox(height: 16),
        _buildStatsGrid(profile),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Contact Information',
          icon: Icons.contact_mail_outlined,
          content: Column(
            children: [
              _buildInfoRow(Icons.email_outlined, widget.user.email),
              const Divider(),
              _buildInfoRow(Icons.phone_outlined, widget.user.phoneNumber ?? 'Not provided'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> profile) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatItem('Experience', '${profile['yearsOfExperience'] ?? 0} Years', onEdit: () => _editNumericStat('Experience', 'yearsOfExperience', profile['yearsOfExperience'] ?? 0)),
        _buildStatItem('Consultation Fee', 'TZS ${profile['consultationFee'] ?? 0}', onEdit: () => _editNumericStat('Consultation Fee', 'consultationFee', (profile['consultationFee'] ?? 0).toDouble())),
        _buildStatItem('Languages', profile['languages'] ?? 'English', onEdit: () => _editTextStat('Languages', 'languages', profile['languages'] ?? 'English')),
        _buildStatItem('Status', (profile['availabilityStatus'] ?? 'available').toUpperCase(), onEdit: () => _editStatus(profile['availabilityStatus'] ?? 'available')),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onEdit}) {
    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (onEdit != null) Icon(Icons.edit_outlined, size: 12, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal)),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationTab(List educations) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addEducation,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Education', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, minimumSize: const Size(double.infinity, 45)),
          ),
        ),
        Expanded(
          child: educations.isEmpty 
            ? _buildEmptyState('No education records found.')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: educations.length,
                itemBuilder: (context, index) {
                  final ed = educations[index];
                  return _buildItemCard(
                    title: ed['degree'],
                    subtitle: ed['institution'],
                    trailing: '${ed['startYear']} - ${ed['endYear'] ?? 'Present'}',
                    description: ed['fieldOfStudy'],
                    icon: Icons.school_outlined,
                    onDelete: () => _deleteEducation(ed['id']),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildExperienceTab(List experiences) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addExperience,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Experience', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, minimumSize: const Size(double.infinity, 45)),
          ),
        ),
        Expanded(
          child: experiences.isEmpty
            ? _buildEmptyState('No work experience records found.')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: experiences.length,
                itemBuilder: (context, index) {
                  final ex = experiences[index];
                  return _buildItemCard(
                    title: ex['position'],
                    subtitle: ex['organization'],
                    trailing: '${ex['startDate']} - ${ex['endDate'] ?? 'Present'}',
                    description: ex['description'],
                    icon: Icons.work_outline,
                    onDelete: () => _deleteExperience(ex['id']),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSkillsTab(List skills) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addSkill,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Skill', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, minimumSize: const Size(double.infinity, 45)),
          ),
        ),
        Expanded(
          child: skills.isEmpty
            ? _buildEmptyState('No skills added.')
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => InputChip(
                    label: Text(s['name']),
                    backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: AppTheme.primaryTeal),
                    onDeleted: () => _deleteSkill(s['id']),
                    deleteIconColor: AppTheme.primaryTeal,
                  )).toList(),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildCertificationsTab(List certs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addCertification,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Certification', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, minimumSize: const Size(double.infinity, 45)),
          ),
        ),
        Expanded(
          child: certs.isEmpty
            ? _buildEmptyState('No certifications listed.')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: certs.length,
                itemBuilder: (context, index) {
                  final c = certs[index];
                  return _buildItemCard(
                    title: c['name'],
                    subtitle: c['issuingOrganization'],
                    trailing: c['issueDate'],
                    icon: Icons.verified_user_outlined,
                    onDelete: () => _deleteCertification(c['id']),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget content, VoidCallback? onEdit}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.primaryTeal),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (onEdit != null)
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildItemCard({required String title, required String subtitle, required String trailing, String? description, required IconData icon, VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryTeal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subtitle, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w500)),
                    Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                if (description != null) ...[const SizedBox(height: 4), Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13))],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.grey)));
  }

  void _editBio(String? currentBio) { _editField('bio', 'Edit Professional Summary', currentBio ?? '', isMultiline: true); }
  void _editNumericStat(String title, String field, num current) { _editField(field, 'Edit $title', current.toString(), isNumeric: true); }
  void _editTextStat(String title, String field, String current) { _editField(field, 'Edit $title', current); }

  void _editField(String field, String title, String current, {bool isMultiline = false, bool isNumeric = false}) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: isMultiline ? 5 : 1,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final Map<String, dynamic> params = {field: isNumeric ? int.tryParse(controller.text) ?? 0 : controller.text};
                if (field == 'consultationFee') params[field] = double.tryParse(controller.text) ?? 0.0;
                
                await ref.read(cvRepositoryProvider).updateProfessionalProfile(
                  bio: field == 'bio' ? controller.text : null,
                  yearsOfExperience: field == 'yearsOfExperience' ? int.tryParse(controller.text) : null,
                  languages: field == 'languages' ? controller.text : null,
                  consultationFee: field == 'consultationFee' ? double.tryParse(controller.text) : null,
                );
                if (!mounted) return;
                ref.invalidate(myCVDataProvider);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editStatus(String current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Availability Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['available', 'busy', 'unavailable'].map((s) => ListTile(
            title: Text(s.toUpperCase()),
            onTap: () async {
              await ref.read(cvRepositoryProvider).updateProfessionalProfile(availabilityStatus: s);
              if (!mounted) return;
              ref.invalidate(myCVDataProvider);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  // ============ CV Actions ============

  void _addEducation() {
    final degreeController = TextEditingController();
    final instController = TextEditingController();
    final fieldController = TextEditingController();
    final yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree (e.g. MD)')),
              TextField(controller: instController, decoration: const InputDecoration(labelText: 'Institution')),
              TextField(controller: fieldController, decoration: const InputDecoration(labelText: 'Field of Study')),
              TextField(controller: yearController, decoration: const InputDecoration(labelText: 'Start Year'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cvRepositoryProvider).addEducation(
                degree: degreeController.text,
                institution: instController.text,
                fieldOfStudy: fieldController.text,
                startYear: int.tryParse(yearController.text) ?? 2020,
              );
              if (!mounted) return;
              ref.invalidate(myCVDataProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteEducation(String id) async {
    await ref.read(cvRepositoryProvider).deleteEducation(id);
    ref.invalidate(myCVDataProvider);
  }

  void _addExperience() {
    final posController = TextEditingController();
    final orgController = TextEditingController();
    final locController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Work Experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: posController, decoration: const InputDecoration(labelText: 'Position')),
              TextField(controller: orgController, decoration: const InputDecoration(labelText: 'Organization')),
              TextField(controller: locController, decoration: const InputDecoration(labelText: 'Location')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cvRepositoryProvider).addWorkExperience(
                position: posController.text,
                organization: orgController.text,
                location: locController.text,
                startDate: DateTime.now().subtract(const Duration(days: 365)),
              );
              if (!mounted) return;
              ref.invalidate(myCVDataProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteExperience(String id) async {
    await ref.read(cvRepositoryProvider).deleteWorkExperience(id);
    ref.invalidate(myCVDataProvider);
  }

  void _addSkill() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Skill Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cvRepositoryProvider).addSkill(name: nameController.text);
              if (!mounted) return;
              ref.invalidate(myCVDataProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteSkill(String id) async {
    await ref.read(cvRepositoryProvider).deleteSkill(id);
    ref.invalidate(myCVDataProvider);
  }

  void _addCertification() {
    final nameController = TextEditingController();
    final orgController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Certification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Certification Name')),
              TextField(controller: orgController, decoration: const InputDecoration(labelText: 'Issuing Organization')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cvRepositoryProvider).addCertification(
                name: nameController.text,
                issuingOrganization: orgController.text,
                issueDate: DateTime.now(),
              );
              if (!mounted) return;
              ref.invalidate(myCVDataProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCertification(String id) async {
    await ref.read(cvRepositoryProvider).deleteCertification(id);
    ref.invalidate(myCVDataProvider);
  }
  
  // ============ Availability Management ============
  
  Widget _buildAvailabilityTab() {
    final availAsync = ref.watch(myAvailabilitiesProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _showAddSlotPicker,
            icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
            label: const Text('Add Time Slot', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: availAsync.when(
              data: (slots) {
                 if (slots.isEmpty) return _buildEmptyState('Plan your schedule by adding availability slots.');
                 return ListView.builder(
                   itemCount: slots.length,
                   itemBuilder: (context, i) {
                     final s = slots[i];
                     return Card(
                       margin: const EdgeInsets.only(bottom: 12),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       child: ListTile(
                         leading: CircleAvatar(
                           backgroundColor: s.isBooked ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                           child: Icon(s.isBooked ? Icons.lock : Icons.event_available, color: s.isBooked ? Colors.orange : Colors.green, size: 20),
                         ),
                         title: Text(DateFormat('EEEE, MMM d').format(s.startTime)),
                         subtitle: Text('${DateFormat('HH:mm').format(s.startTime)} - ${DateFormat('HH:mm').format(s.endTime)}'),
                         trailing: s.isBooked 
                           ? Chip(label: const Text('Booked', style: TextStyle(fontSize: 10)), backgroundColor: Colors.orange.withValues(alpha: 0.1))
                           : IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteSlot(s.id)),
                       ),
                     );
                   },
                 );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSlotPicker() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
    if (date == null) return;
    
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final end = start.add(const Duration(minutes: 30));

    try {
      await ref.read(availabilityRepositoryProvider).createAvailability(start, end);
      if (!mounted) return;
      ref.invalidate(myAvailabilitiesProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot added!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _deleteSlot(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text('Are you sure you want to remove this availability slot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(availabilityRepositoryProvider).deleteAvailability(id);
      if (!mounted) return;
      ref.invalidate(myAvailabilitiesProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot removed'), backgroundColor: Colors.blueGrey));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
