import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:afyalink/core/theme.dart';
import 'package:afyalink/features/offers/data/models/product_model.dart';
import 'package:afyalink/features/healthcare/data/repositories/healthcare_repository.dart';
import 'package:afyalink/features/healthcare/data/repositories/doctors_repository.dart';
import 'package:afyalink/features/offers/data/repositories/marketplace_repository.dart';
import 'package:afyalink/features/home/presentation/pages/product_detail_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/doctor_detail_page.dart';
import 'package:afyalink/features/healthcare/presentation/pages/hospital_detail_page.dart';
import 'package:afyalink/features/healthcare/presentation/widgets/hospital_card.dart';
import 'package:afyalink/features/cart/presentation/providers/cart_provider.dart';
import 'package:afyalink/features/cart/data/models/cart_model.dart';
import 'package:afyalink/features/profile/presentation/providers/wishlist_provider.dart';
import 'package:afyalink/features/profile/data/repositories/settings_repository.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  final List<String> _recentSearches = ['Panadol', 'Vitamin C', 'Syrup', 'Face Mask'];
  Timer? _debounce;

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
              fillColor: AppTheme.backgroundWhite,
            ),
            onChanged: (val) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                setState(() => _query = val);
              });
            },
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
    final productsAsync = ref.watch(productsProvider(_query.isNotEmpty ? _query : null));
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return Column(
      children: [
        if (_query.isNotEmpty) _buildCategoryFilters(categoriesAsync),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final currencyConf = ref.watch(currencySettingsProvider).value;
              final symbol = currencyConf?.symbol ?? 'Tsh';
              
              var filtered = products;

              if (_selectedCategory != 'All') {
                filtered = filtered.where((p) => p.categoryName == _selectedCategory).toList();
              }

              if (_query.isEmpty) return _buildRecentSearches();
              if (filtered.isEmpty) return _buildNoResults();
              
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildSmartProductCard(context, ref, filtered[index], symbol),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.maybeWhen(
      data: (categories) {
        final list = ['All', ...categories.map((c) => c.name)];
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final cat = list[i];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                  selectedColor: AppTheme.primaryTeal,
                  backgroundColor: AppTheme.backgroundWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _recentSearches.map((s) => ActionChip(
            label: Text(s),
            onPressed: () {
              _searchController.text = s;
              setState(() => _query = s);
            },
          )).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Trending Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildTrendingGrid(),
      ],
    );
  }

  Widget _buildTrendingGrid() {
    final categories = ['Vitamins', 'Pain Relief', 'Skincare', 'Baby Care'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.5),
      itemCount: categories.length,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(color: AppTheme.primaryTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.1))),
        child: Center(child: Text(categories[i], style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryTeal))),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No products found matching your search', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSmartProductCard(BuildContext context, WidgetRef ref, Product product, String symbol) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  color: AppTheme.backgroundWhite,
                  width: double.infinity,
                  child: product.images.isNotEmpty 
                    ? Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.medication))
                    : const Icon(Icons.medication, size: 40, color: AppTheme.textSecondary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 14)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_circle, color: AppTheme.primaryTeal),
                        onPressed: () {
                          ref.read(cartProvider.notifier).addItem(CartItem(productId: product.id, name: product.name, price: product.price, image: product.images.isNotEmpty ? product.images.first : null));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart'), duration: Duration(seconds: 1)));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthcareTab() {
    final filters = ['All', 'PHARMACY', 'LAB', 'CLINIC', 'HOSPITAL'];
    final hospitalsAsync = ref.watch(hospitalsProvider((type: null, search: _query.isNotEmpty ? _query : null)));
    
    return hospitalsAsync.when(
      data: (hospitals) {
        final filtered = hospitals;
        
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
    final doctorsAsync = ref.watch(doctorsProvider((search: _query.isNotEmpty ? _query : null, specialty: null)));
    return doctorsAsync.when(
      data: (doctors) {
        final filtered = doctors;
        
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
