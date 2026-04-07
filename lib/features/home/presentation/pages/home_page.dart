import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/offers/data/models/product_model.dart';
import 'package:app/features/offers/data/models/brand_model.dart';
import 'package:app/features/offers/data/repositories/marketplace_repository.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';
import 'package:app/features/offers/presentation/pages/category_page.dart';
import 'package:app/features/offers/presentation/pages/offers_page.dart';
import 'package:app/features/auth/data/repositories/auth_repository.dart';
import 'package:app/features/home/presentation/pages/product_detail_page.dart';
import 'package:app/features/home/presentation/widgets/dashboards/patient_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/doctor_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/doctor_schedule_tab.dart';
import 'package:app/features/home/presentation/widgets/dashboards/doctor_patients_tab.dart';
import 'package:app/features/home/presentation/widgets/dashboards/doctor_chat_tab.dart';
import 'package:app/features/home/presentation/widgets/dashboards/lab_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/pharmacy_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/admin_dashboard.dart';
import 'package:app/features/home/presentation/widgets/dashboards/hospital_dashboard.dart';
import 'package:app/features/healthcare/presentation/pages/healthcare_page.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/cart/presentation/pages/cart_page.dart';
import 'package:app/features/cart/data/models/cart_model.dart';
import 'package:app/features/home/presentation/pages/search_page.dart';
import 'package:app/features/healthcare/presentation/pages/telemedicine_page.dart';
import 'package:app/features/offers/presentation/pages/brands_page.dart';
import 'package:app/features/profile/presentation/pages/settings_page.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';
import 'package:app/features/profile/presentation/pages/doctor_profile_page.dart';
import 'package:app/features/auth/presentation/pages/login_page.dart';
import 'package:app/core/widgets/product_image.dart';
import 'package:app/core/providers/location_provider.dart';
import 'package:app/features/home/presentation/widgets/location_picker_sheet.dart';

// ─── Bottom Nav Index Provider ────────────────────────────────────────────────
final tabIndexProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final tabIndex = ref.watch(tabIndexProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return userAsync.when(
      data: (user) {
        // If not logged in or is a patient, show the 5-tab e-commerce shell
        if (user == null || user.role == null || user.role!.toUpperCase() == 'PATIENT') {
          return _buildMainShell(context, ref, tabIndex, user: user);
        }
        // Otherwise show the specialized dashboard for their role
        return _buildRoleDashboard(context, ref, user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => _buildMainShell(context, ref, tabIndex),
    );
  }

  // ─── Role-based dashboards (pharmacist, doctor etc.) ─────────────────────
  Widget _buildRoleDashboard(BuildContext context, WidgetRef ref, User user) {
    if (user.role?.toUpperCase() == 'DOCTOR') {
      return _buildDoctorShell(context, ref, user);
    }

    Widget dashboard;
    String title = 'Dashboard';

    switch (user.role?.toUpperCase()) {
      case 'LAB_TECHNICIAN':
      case 'LAB':
        dashboard = LabDashboard(user: user);
        title = 'Lab Panel';
        break;
      case 'PHARMACIST':
      case 'PHARMACY':
        dashboard = PharmacyDashboard(user: user);
        title = 'Pharmacy Panel';
        break;
      case 'HOSPITAL_ADMIN':
      case 'HOSPITAL':
        dashboard = HospitalDashboard(user: user);
        title = 'Hospital Panel';
        break;
      case 'ADMIN':
      case 'STAFF':
      case 'SUPERUSER':
        dashboard = AdminDashboard(user: user);
        title = 'Admin Panel';
        break;
      default:
        return _buildMainShell(context, ref, ref.read(tabIndexProvider));
    }

    return dashboard;
  }

  Widget _buildDoctorShell(BuildContext context, WidgetRef ref, User user) {
    final tabIndex = ref.watch(tabIndexProvider);
    final tabs = [
      DoctorDashboard(user: user),
      _buildDoctorScheduleTab(user),
      _buildDoctorPatientsTab(user),
      _buildDoctorChatTab(user),
      DoctorProfilePage(user: user),
    ];

    return Scaffold(
      body: IndexedStack(index: tabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabIndex,
        onTap: (i) => ref.read(tabIndexProvider.notifier).state = i,
        selectedItemColor: AppTheme.primaryTeal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDoctorScheduleTab(User user) {
    return DoctorScheduleTab(user: user);
  }

  Widget _buildDoctorPatientsTab(User user) {
    return DoctorPatientsTab(user: user);
  }

  Widget _buildDoctorChatTab(User user) {
    return const DoctorChatTab();
  }

  // ─── Main shell with 5-tab bottom nav ────────────────────────────────────
  Widget _buildMainShell(BuildContext context, WidgetRef ref, int tabIndex, {User? user}) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final tabs = [
      (user != null && user.role?.toUpperCase() == 'PATIENT') ? PatientDashboard(user: user) : _buildGuestHome(context, ref),
      const OffersPage(),
      const HealthcarePage(),
      const TelemedicinePage(),
      _buildProfileTab(context, ref),
    ];

    return Scaffold(
      appBar: _buildAppBar(context, ref, selectedLocation),
      body: IndexedStack(index: tabIndex, children: tabs),
      bottomNavigationBar: _buildBottomNav(context, ref, tabIndex),
    );
  }


  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, String location) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: AppTheme.borderColor,
      titleSpacing: 0,
      title: InkWell(
        onTap: () => _showLocationPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryTeal, size: 14),
                  const SizedBox(width: 3),
                  const Text('Deliver to', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                children: [
                  Flexible(child: Text(location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primaryTeal),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.maybeWhen(
              data: (user) {
                if (user == null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 0.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: const Text('Login', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
        Consumer(
          builder: (context, ref, child) {
            final cartCount = ref.watch(cartProvider).items.length;
            return Stack(
              children: [
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryTeal),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPickerSheet(),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int index) {
    return BottomNavigationBar(
      currentIndex: index,
      onTap: (i) => ref.read(tabIndexProvider.notifier).state = i,
      selectedItemColor: AppTheme.primaryTeal,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), activeIcon: Icon(Icons.medication), label: 'Medicines'),
        BottomNavigationBarItem(icon: Icon(Icons.biotech_outlined), activeIcon: Icon(Icons.biotech), label: 'Health Services'),
        BottomNavigationBarItem(icon: Icon(Icons.video_call_outlined), activeIcon: Icon(Icons.video_call), label: 'Consult'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildProfileTab(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const LoginPage();
    }
    return const ProfilePage();
  }

  // ─── Guest Home Body ──────────────────────────────────────────────────────
  Widget _buildGuestHome(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final productsAsync = ref.watch(productsProvider(null));
    final segmentsAsync = ref.watch(allSegmentsProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text('Search medicines, health products...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          // ── Promotional Banner Carousel ───────────────────────────────────
          const _PromoBannerCarousel(),
          const SizedBox(height: 20),

          // ── Discover Our Offerings (PharmEasy-style tiles) ────────────────
          _sectionHeader('Discover Our Offerings'),
          const SizedBox(height: 10),
          _buildOfferingTiles(context, ref),
          const SizedBox(height: 20),

          // ── Shop by Category (horizontal strip) ───────────────────────────
          _sectionHeader('Shop by Category', onViewAll: () {}),
          const SizedBox(height: 10),
          categoriesAsync.when(
            data: (cats) => _buildCategoryStrip(context, ref, cats),
            loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),

          // ── Deals of the Day ─────────────────────────────────────────────
          _dealsHeader(),
          const SizedBox(height: 10),
          productsAsync.when(
            data: (products) => _buildDealsStrip(context, ref, products),
            loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),

          // ── Product Segments (Trending, New Launches, etc.) ───────────────
          segmentsAsync.when(
            data: (segments) => Column(
              children: segments.map((seg) {
                if (seg.products.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    _sectionHeader(seg.title, onViewAll: () {}),
                    const SizedBox(height: 10),
                    _buildProductStrip(context, ref, seg.products),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          // ── Featured Brands ───────────────────────────────────────────────
          _sectionHeader('Featured Brands', onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandsPage()))),
          const SizedBox(height: 10),
          brandsAsync.when(
            data: (brands) => _buildBrandStrip(context, ref, brands),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // ── Health Store (Product Grid) ───────────────────────────────────
          _sectionHeader('Health Store', onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()))),
          const SizedBox(height: 12),
          productsAsync.when(
            data: (products) => _buildProductGrid(context, ref, products),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ─── Section headers ──────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Text('View All', style: TextStyle(fontSize: 13, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _dealsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Text('Deals of the Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade200)),
            child: Row(children: [
              Icon(Icons.local_offer, size: 12, color: Colors.red.shade600),
              const SizedBox(width: 4),
              Text('Today Only', style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Discover Our Offerings tiles ─────────────────────────────────────────
  Widget _buildOfferingTiles(BuildContext context, WidgetRef ref) {
    final tiles = [
      {'label': 'Medicines', 'sub': 'SAVE 25%', 'icon': Icons.medication_outlined, 'color': const Color(0xFF4CAF50), 'bg': const Color(0xFFE8F5E9)},
      {'label': 'Health Services', 'sub': 'BUY 1 GET 1', 'icon': Icons.biotech_outlined, 'color': const Color(0xFF2196F3), 'bg': const Color(0xFFE3F2FD)},
      {'label': 'Doctor Consult', 'sub': 'BOOK NOW', 'icon': Icons.video_call_outlined, 'color': const Color(0xFF9C27B0), 'bg': const Color(0xFFF3E5F5)},
      {'label': 'Healthcare', 'sub': 'UPTO 60% OFF', 'icon': Icons.favorite_border_outlined, 'color': const Color(0xFFE91E63), 'bg': const Color(0xFFFCE4EC)},
      {'label': 'Pharmacy', 'sub': 'NEAR YOU', 'icon': Icons.local_pharmacy_outlined, 'color': const Color(0xFF009688), 'bg': const Color(0xFFE0F2F1)},
      {'label': 'Wellness', 'sub': 'EXPLORE', 'icon': Icons.spa_outlined, 'color': const Color(0xFFFF9800), 'bg': const Color(0xFFFFF3E0)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, i) {
          final tile = tiles[i];
          final color = tile['color'] as Color;
          final bg = tile['bg'] as Color;
          return GestureDetector(
            onTap: () {
              if (i == 1 || i == 4) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthcarePage()));
              } else if (i == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(tile['icon'] as IconData, color: color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(tile['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  Text(tile['sub'] as String, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Category horizontal strip ────────────────────────────────────────────
  Widget _buildCategoryStrip(BuildContext context, WidgetRef ref, List<Category> categories) {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(category: cat))),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: cat.image != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(cat.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.category_outlined, color: AppTheme.primaryTeal, size: 28)))
                        : const Icon(Icons.category_outlined, color: AppTheme.primaryTeal, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(cat.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Deals of the Day / Product strips ───────────────────────────────────
  Widget _buildDealsStrip(BuildContext context, WidgetRef ref, List<Product> products) {
    // Filter out items that actually have a discount, otherwise fallback to top products
    var deals = products.where((p) => p.discountPercentage > 0 || (p.originalPrice != null && p.originalPrice! > p.price)).toList();
    if (deals.isEmpty) {
      deals = products.take(12).toList();
    } else {
      deals = deals.take(12).toList();
    }
    return _buildProductStrip(context, ref, deals, showDiscount: true);
  }

  Widget _buildProductStrip(BuildContext context, WidgetRef ref, List<Product> products, {bool showDiscount = false}) {
    return SizedBox(
      height: 232,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length > 12 ? 12 : products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, ref, product, showDiscount: showDiscount);
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, WidgetRef ref, List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: products.length > 20 ? 20 : products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, ref, product, showDiscount: true, width: double.infinity);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product, {bool showDiscount = false, double? width}) {
    final currencyConf = ref.read(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(idOrSlug: product.slug))),
      child: Container(
        width: width ?? 144,
        margin: width == null ? const EdgeInsets.only(right: 12) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: ProductImage(
                      url: product.images.isNotEmpty ? product.images.first : null,
                      height: 110,
                      width: double.infinity,
                    ),
                  ),
                  if (showDiscount && product.discountPercentage > 0)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(6)),
                        child: Text('${product.discountPercentage.toInt()}% OFF', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 4),
                  Text('$symbol ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryTeal)),
                  if (product.originalPrice != null && product.originalPrice! > product.price)
                    Text('$symbol ${product.originalPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: AppTheme.textSecondary)),
                  Consumer(
                    builder: (context, ref, child) {
                      final cartState = ref.watch(cartProvider);
                      final existingItem = cartState.items.firstWhere(
                        (item) => item.productId == product.id,
                        orElse: () => CartItem(productId: '', name: '', price: 0),
                      );

                      if (existingItem.productId.isNotEmpty) {
                        return Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32),
                                icon: const Icon(Icons.remove, size: 16, color: AppTheme.primaryTeal),
                                onPressed: () {
                                  if (existingItem.quantity > 1) {
                                    ref.read(cartProvider.notifier).updateQuantity(existingItem.productId, existingItem.quantity - 1);
                                  } else {
                                    ref.read(cartProvider.notifier).removeItem(existingItem.productId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${product.name} removed from cart!'), duration: const Duration(seconds: 1)),
                                    );
                                  }
                                },
                              ),
                              Text('${existingItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal)),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32),
                                icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryTeal),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(existingItem.productId, existingItem.quantity + 1);
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).addItem(CartItem(
                              productId: product.id,
                              name: product.name,
                              price: product.price,
                              image: product.images.isNotEmpty ? product.images.first : null,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added!'), duration: const Duration(seconds: 1)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 28),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ─── Featured Brands strip ────────────────────────────────────────────────
  Widget _buildBrandStrip(BuildContext context, WidgetRef ref, List<Brand> brands) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandsPage())),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  brand.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(url: brand.logo, height: 40, width: 80, fit: BoxFit.contain))
                      : Icon(Icons.business_outlined, size: 30, color: AppTheme.primaryTeal.withOpacity(0.5)),
                  const SizedBox(height: 6),
                  Text(brand.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


// ─── Auto-sliding Promo Banner Carousel ───────────────────────────────────────
class _PromoBannerCarousel extends StatefulWidget {
  const _PromoBannerCarousel();

  @override
  State<_PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<_PromoBannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _timer;

  final _banners = const [
    _BannerData(
      gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      title: '25% OFF on all Medicines',
      subtitle: 'Use code DAWAFAST25 at checkout',
      icon: Icons.medication,
    ),
    _BannerData(
      gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      title: 'Health Services at Home',
      subtitle: 'Book certified health services online',
      icon: Icons.biotech,
    ),
    _BannerData(
      gradient: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      title: 'Consult a Doctor',
      subtitle: 'Video consultation from TZS 2,000',
      icon: Icons.video_call,
    ),
    _BannerData(
      gradient: [Color(0xFFE65100), Color(0xFFFFA726)],
      title: 'Wellness Essentials',
      subtitle: 'Premium healthcare products on offer',
      icon: Icons.spa,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = (_current + 1) % _banners.length;
      if (_controller.hasClients) {
        _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _banners.length,
            itemBuilder: (context, i) {
              final banner = _banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: banner.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                            const SizedBox(height: 8),
                            Text(banner.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: Text('Shop Now', style: TextStyle(color: banner.gradient[0], fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      Icon(banner.icon, color: Colors.white.withOpacity(0.25), size: 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _current == i ? 20 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: _current == i ? AppTheme.primaryTeal : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }
}

class _BannerData {
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final IconData icon;
  const _BannerData({required this.gradient, required this.title, required this.subtitle, required this.icon});
}

