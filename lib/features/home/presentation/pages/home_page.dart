import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/offers/presentation/pages/category_page.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';
import 'package:app/features/home/presentation/widgets/dashboards/patient_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/doctor_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/lab_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/pharmacy_dashboard.dart';
import 'package:app/features/healthcare/presentation/pages/healthcare_page.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/cart/presentation/pages/cart_page.dart';
import 'package:app/features/cart/data/models/cart_model.dart';
import 'package:app/features/home/presentation/pages/search_page.dart';
import 'package:app/features/healthcare/presentation/pages/telemedicine_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return _buildGuestHome(context, ref);
        return _buildRoleDashboard(context, ref, user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => _buildGuestHome(context, ref),
    );
  }

  Widget _buildRoleDashboard(BuildContext context, WidgetRef ref, User user) {
    Widget dashboard;
    String location = user.patientProfile?.location ?? 'Select Location';

    switch (user.role?.toUpperCase()) {
      case 'DOCTOR':
        dashboard = DoctorDashboard(user: user);
        break;
      case 'LAB_TECHNICIAN':
        dashboard = LabDashboard(user: user);
        break;
      case 'PHARMACIST':
        dashboard = PharmacyDashboard(user: user);
        break;
      case 'PATIENT':
      default:
        dashboard = PatientDashboard(user: user);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deliver to', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Row(
              children: [
                Flexible(child: Text(location, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          Consumer(
            builder: (context, ref, child) {
              final cartCount = ref.watch(cartProvider).items.length;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: dashboard,
    );
  }

  Widget _buildGuestHome(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final productsAsync = ref.watch(productsProvider);
    final segmentsAsync = ref.watch(allSegmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliver to', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            Row(
              children: [
                Text('Guest Location', style: TextStyle(fontSize: 14)),
                Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          Consumer(
            builder: (context, ref, child) {
              final cartCount = ref.watch(cartProvider).items.length;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text('Search medicine/healthcare products', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),

            // Hero Slider with generated premium asset
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'lib/assets/images/medical_placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Category Grid
            categoriesAsync.when(
              data: (categories) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: categories.length > 8 ? 8 : categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    String assetPath = 'lib/assets/images/category_placeholder.png';
                    if (cat.name.toLowerCase().contains('medicine')) assetPath = 'lib/assets/images/medicine_category.png';
                    if (cat.name.toLowerCase().contains('lab')) assetPath = 'lib/assets/images/lab_test_category.png';
                    if (cat.name.toLowerCase().contains('wellness')) assetPath = 'lib/assets/images/wellness_category.png';
                    if (cat.name.toLowerCase().contains('healthcare')) assetPath = 'lib/assets/images/healthcare_category.png';

                    return _buildCategoryItem(context, ref, assetPath, cat.name, category: cat);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildMockCategories(context, ref),
            ),

            const SizedBox(height: 24),

            // Product Segments
            segmentsAsync.when(
              data: (segments) {
                return Column(
                  children: segments.map((segment) {
                    if (segment.products.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(segment.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal))),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16),
                            itemCount: segment.products.length,
                            itemBuilder: (context, index) {
                              return _buildDealCard(context, ref, segment.products[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            // Secondary Deals section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trending Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal))),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: productsAsync.when(
                data: (products) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildDealCard(context, ref, products[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildMockDeals(context, ref),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMockCategories(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildCategoryItem(context, ref, 'lib/assets/images/medicine_category.png', 'Medicines'),
        _buildCategoryItem(context, ref, 'lib/assets/images/lab_test_category.png', 'Lab Tests'),
        _buildCategoryItem(context, ref, 'lib/assets/images/healthcare_category.png', 'Healthcare'),
        _buildCategoryItem(context, ref, 'lib/assets/images/medical_placeholder.png', 'Surgeries'),
        _buildCategoryItem(context, ref, 'lib/assets/images/medical_placeholder.png', 'Pharmacy'),
        _buildCategoryItem(context, ref, 'lib/assets/images/wellness_category.png', 'Wellness'),
        _buildCategoryItem(context, ref, 'lib/assets/images/medical_placeholder.png', 'Consult'),
        _buildCategoryItem(context, ref, 'lib/assets/images/category_placeholder.png', 'All'),
      ],
    );
  }

  Widget _buildMockDeals(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildDealCard(context, ref, Product(
          id: 'mock_$index',
          name: 'Product Name ${index + 1}',
          slug: 'mock-product',
          price: 199,
          originalPrice: 249,
          images: [],
        ));
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, WidgetRef ref, String assetPath, String label, {Category? category}) {
    return GestureDetector(
      onTap: () {
        if (category != null) {
          final name = category.name.toLowerCase();
          if (name.contains('healthcare') || name.contains('lab') || name.contains('hospital') || name.contains('clinic')) {
            ref.read(selectedHealthcareFilterProvider.notifier).state = 
                name.contains('lab') ? 'Lab' : 
                name.contains('clinic') ? 'Clinic' : 
                name.contains('pharmacy') ? 'Pharmacy' : 'All';
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthcarePage()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(category: category)));
          }
        } else {
          // For mock categories
          if (label == 'Healthcare' || label == 'Lab Tests' || label == 'Clinic') {
            ref.read(selectedHealthcareFilterProvider.notifier).state = 
                label.contains('Lab') ? 'Lab' : 
                label.contains('Clinic') ? 'Clinic' : 'All';
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthcarePage()));
          } else if (label == 'Consult') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(assetPath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, WidgetRef ref, Product product) {
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug)));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.images.isNotEmpty 
                    ? Image.network(product.images.first, fit: BoxFit.cover)
                    : Image.asset('lib/assets/images/product_placeholder.png', fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
                Text(product.name, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (product.discountPercentage > 0)
                  Text('${product.discountPercentage.toInt()}% OFF', 
                    style: const TextStyle(fontSize: 12, color: AppTheme.accentPink, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
