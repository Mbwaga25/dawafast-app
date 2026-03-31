import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:app/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';
import 'package:app/features/healthcare/presentation/pages/doctor_detail_page.dart';
import 'package:app/features/healthcare/presentation/pages/hospital_detail_page.dart';
import 'package:app/features/healthcare/presentation/widgets/hospital_card.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/cart/data/models/cart_model.dart';
import 'package:app/features/profile/presentation/providers/wishlist_provider.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search for anything...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ) : null,
              border: InputBorder.none,
              filled: true,
              fillColor: AppTheme.backgroundGray,
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryTeal,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Healthcare'),
            Tab(text: 'Doctors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildHealthcareTab(),
          _buildDoctorsTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final productsAsync = ref.watch(productsProvider);
    return productsAsync.when(
      data: (products) {
        final currencyConf = ref.watch(currencySettingsProvider).value;
        final symbol = currencyConf?.symbol ?? 'Tsh';
        
        final filtered = products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
        if (_query.isEmpty) return const Center(child: Text('Start searching for products'));
        if (filtered.isEmpty) return const Center(child: Text('No products found'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final p = filtered[index];
            return ListTile(
              leading: Icon(Icons.medical_services_outlined, color: AppTheme.primaryTeal),
              title: Text(p.name),
              subtitle: Text('$symbol ${p.price.toStringAsFixed(0)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final isFav = ref.watch(wishlistProvider.notifier).isFavorite(p.id);
                      return IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: AppTheme.accentPink, size: 20),
                        onPressed: () => ref.read(wishlistProvider.notifier).toggle(p),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryTeal, size: 20),
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(
                        CartItem(
                          productId: p.id,
                          name: p.name,
                          price: p.price,
                          image: p.images.isNotEmpty ? p.images.first : null,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${p.name} added to cart'), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: p.slug))),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHealthcareTab() {
    final filters = ['All', 'PHARMACY', 'LAB', 'CLINIC', 'HOSPITAL'];
    final hospitalsAsync = ref.watch(hospitalsProvider(null));
    
    return hospitalsAsync.when(
      data: (hospitals) {
        final filtered = hospitals.where((h) => 
          h.name.toLowerCase().contains(_query.toLowerCase()) || 
          (h.city?.toLowerCase().contains(_query.toLowerCase()) ?? false)
        ).toList();
        
        if (_query.isEmpty) return const Center(child: Text('Search for pharmacies, labs, hospitals...'));
        if (filtered.isEmpty) return const Center(child: Text('No results found'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final h = filtered[index];
            return HospitalCard(hospital: h);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDoctorsTab() {
    final doctorsAsync = ref.watch(doctorsProvider((search: null, specialty: null)));
    return doctorsAsync.when(
      data: (doctors) {
        final filtered = doctors.where((d) => 
          d.fullName.toLowerCase().contains(_query.toLowerCase()) || 
          (d.specialty?.toLowerCase().contains(_query.toLowerCase()) ?? false)
        ).toList();
        
        if (_query.isEmpty) return const Center(child: Text('Search for doctors by name or specialty'));
        if (filtered.isEmpty) return const Center(child: Text('No doctors found'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final d = filtered[index];
            return ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.primaryTeal.withOpacity(0.1), child: const Icon(Icons.person, color: AppTheme.primaryTeal)),
              title: Text('Dr. ${d.fullName}'),
              subtitle: Text(d.specialty ?? 'General Physician'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailPage(doctorId: d.id))),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
