import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/afyalink_loader.dart';
import '../../../offers/data/models/product_model.dart';
import '../../../offers/data/models/brand_model.dart';
import '../../../offers/data/repositories/marketplace_repository.dart';
import '../../../profile/data/repositories/settings_repository.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/data/models/cart_model.dart';

class GuestHomeContent extends ConsumerWidget {
  const GuestHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onTap: () => context.push('/search'),
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
          const PromoBannerCarousel(),
          const SizedBox(height: 20),

          // ── Discover Our Offerings ────────────────
          _sectionHeader('Discover Our Offerings'),
          const SizedBox(height: 10),
          _buildOfferingTiles(context, ref),
          const SizedBox(height: 20),

          // ── Shop by Category ───────────────────────────
          _sectionHeader('Shop by Category', onViewAll: () {}),
          const SizedBox(height: 10),
          categoriesAsync.when(
            data: (cats) => _buildCategoryStrip(context, ref, cats),
            loading: () => const SizedBox(height: 96, child: AfyaLinkLoader(size: 40, message: '')),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),

          // ── Deals of the Day ─────────────────────────────────────────────
          _dealsHeader(),
          const SizedBox(height: 10),
          productsAsync.when(
            data: (products) => _buildDealsStrip(context, ref, products),
            loading: () => const SizedBox(height: 220, child: AfyaLinkLoader(size: 60, message: '')),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),

          // ── Product Segments ───────────────
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
          _sectionHeader('Featured Brands', onViewAll: () {}),
          const SizedBox(height: 10),
          brandsAsync.when(
            data: (brands) => _buildBrandStrip(context, ref, brands),
            loading: () => const SizedBox(height: 100, child: AfyaLinkLoader(size: 40, message: '')),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // ── Health Store (Product Grid) ───────────────────────────────────
          _sectionHeader('Health Store', onViewAll: () => context.push('/search')),
          const SizedBox(height: 12),
          productsAsync.when(
            data: (products) => _buildProductGrid(context, ref, products),
            loading: () => const Padding(padding: EdgeInsets.all(20), child: AfyaLinkLoader(size: 80, message: 'Loading Store...')),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

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
              switch (i) {
                case 0: context.push('/search'); break; // Medicines
                case 1: context.push('/labs'); break; // Health Services
                case 2: context.push('/telemedicine'); break; // Doctor Consult
                case 3: context.push('/healthcare'); break; // Healthcare
                case 4: context.push('/pharmacies'); break; // Pharmacy
                case 5: context.push('/search'); break; // Wellness
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
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
            onTap: () => context.push('/search?category=${cat.id}'), // Or similar logic if CategoryPage is needed
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.07),
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

  Widget _buildDealsStrip(BuildContext context, WidgetRef ref, List<Product> products) {
    var deals = products.where((p) => p.discountPercentage > 0 || (p.originalPrice != null && p.originalPrice! > p.price)).toList();
    if (deals.isEmpty) deals = products.take(12).toList();
    else deals = deals.take(12).toList();
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
      onTap: () => context.push('/product/${product.slug}'),
      child: Container(
        width: width ?? 144,
        margin: width == null ? const EdgeInsets.only(right: 12) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(CartItem(
                          productId: product.id,
                          name: product.name,
                          price: product.price,
                          image: product.images.isNotEmpty ? product.images.first : null,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 28),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            onTap: () => context.push('/search?brand=${brand.id}'),
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
                      : Icon(Icons.business_outlined, size: 30, color: AppTheme.primaryTeal.withValues(alpha: 0.5)),
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

class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _timer;

  final _banners = const [
    _BannerData(
      gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      title: '25% OFF on all Medicines',
      subtitle: 'Use code AFYALINK25 at checkout',
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
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controller.hasClients) {
        _current = (_current + 1) % _banners.length;
        _controller.animateToPage(_current, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
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
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final b = _banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: b.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(b.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (i == 0) context.push('/search');
                              else if (i == 1) context.push('/labs');
                              else context.push('/telemedicine');
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: b.gradient[0], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0)),
                            child: const Text('Shop Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    Icon(b.icon, color: Colors.white.withValues(alpha: 0.3), size: 100),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) => Container(
            width: 8, height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _current == index ? AppTheme.primaryTeal : Colors.grey.shade300),
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
