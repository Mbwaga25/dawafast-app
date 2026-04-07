import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:app/core/theme.dart';
import 'package:app/core/api_client.dart';
import 'package:app/features/cart/presentation/pages/order_success_page.dart';
import 'package:app/features/cart/presentation/providers/cart_provider.dart';
import 'package:app/features/profile/data/repositories/settings_repository.dart';

// --- Riverpod providers for geo location ---

class GeoAddress {
  final double lat;
  final double lon;
  final String? street;
  final String? ward;
  final String? district;
  final String? region;
  final String? country;

  GeoAddress({
    required this.lat,
    required this.lon,
    this.street,
    this.ward,
    this.district,
    this.region,
    this.country,
  });

  String get formattedAddress {
    final parts = [
      if (street?.isNotEmpty == true) street,
      if (ward?.isNotEmpty == true) ward,
      if (district?.isNotEmpty == true) district,
      if (region?.isNotEmpty == true) region,
      if (country?.isNotEmpty == true) country,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Location detected';
  }
}

// Provider that uses the browser Geolocation API + backend reverse geocode
final geoAddressProvider = FutureProvider<GeoAddress?>((ref) async {
  const reverseGeocodeQuery = r'''
    query ReverseGeocode($latitude: Float!, $longitude: Float!) {
      reverseGeocode(latitude: $latitude, longitude: $longitude) {
        country
        region
        district
        ward
        street
      }
    }
  ''';

  // Use browser geolocation (works on Flutter Web)
  final completer = Future<Map<String, double>>(() async {
    final geo = html.window.navigator.geolocation;
    final pos = await geo.getCurrentPosition(enableHighAccuracy: true);
    return {
      'lat': pos.coords!.latitude!.toDouble(),
      'lon': pos.coords!.longitude!.toDouble(),
    };
  });

  try {
    final coords = await completer.timeout(const Duration(seconds: 10));
    final lat = coords['lat']!;
    final lon = coords['lon']!;

    final QueryOptions options = QueryOptions(
      document: gql(reverseGeocodeQuery),
      variables: {'latitude': lat, 'longitude': lon},
      fetchPolicy: FetchPolicy.networkOnly,
    );
    final result = await ApiClient.client.value.query(options);
    final data = result.data?['reverseGeocode'];

    return GeoAddress(
      lat: lat,
      lon: lon,
      street: data?['street'],
      ward: data?['ward'],
      district: data?['district'],
      region: data?['region'],
      country: data?['country'],
    );
  } catch (e) {
    return null;
  }
});

// ---- Checkout Page ----

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final currencyConf = ref.watch(currencySettingsProvider).value;
    final symbol = currencyConf?.symbol ?? 'Tsh';
    final geoAsync = ref.watch(geoAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Delivery Address'),
            const SizedBox(height: 12),
            _buildAddressCard(context, geoAsync),
            const SizedBox(height: 24),
            _buildSectionHeader('Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Order Summary'),
            const SizedBox(height: 12),
            _buildOrderSummary(cartState, symbol),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cartState.items.isEmpty ? null : () => _placeOrder(context, ref),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildAddressCard(BuildContext context, AsyncValue<GeoAddress?> geoAsync) {
    return Card(
      child: geoAsync.when(
        loading: () => const ListTile(
          leading: Icon(Icons.location_on_outlined, color: AppTheme.primaryTeal),
          title: Text('Detecting location...'),
          subtitle: LinearProgressIndicator(),
        ),
        error: (err, __) => ListTile(
          leading: const Icon(Icons.location_off_outlined, color: Colors.orange),
          title: const Text('Location unavailable'),
          subtitle: const Text('Using default address'),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          onTap: () => _showAddressPicker(context),
        ),
        data: (geo) {
          if (geo == null) {
            return ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryTeal),
              title: const Text('Delivery Address'),
              subtitle: const Text('Tap to set your location'),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              onTap: () => _showAddressPicker(context),
            );
          }
          return ListTile(
            leading: const Icon(Icons.my_location, color: AppTheme.primaryTeal),
            title: Text(geo.formattedAddress, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: geo.ward != null || geo.district != null
                ? Text(
                    [if (geo.ward != null) geo.ward!, if (geo.district != null) geo.district!].join(' — '),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  )
                : null,
            trailing: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
            onTap: () => _showAddressPicker(context),
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryTeal),
        title: const Text('Mobile Money (M-Pesa)'),
        subtitle: const Text('**** **** **** 4567'),
        trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
      ),
    );
  }

  Widget _buildOrderSummary(cartState, String symbol) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...cartState.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('${item.quantity}x ${item.name}', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text('$symbol ${(item.price * item.quantity).toStringAsFixed(0)}'),
                ],
              ),
            )).toList(),
            const Divider(height: 24),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary)),
                Text('$symbol ${cartState.subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery', style: TextStyle(color: AppTheme.textSecondary)),
                Text('$symbol ${cartState.deliveryFee.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$symbol ${cartState.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 2), () {
      ref.read(cartProvider.notifier).clear();
      Navigator.pop(context); // Pop loading dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessPage(orderId: 'DWF-789234')),
      );
    });
  }

  void _showAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppTheme.primaryTeal),
              title: const Text('Use Current Location'),
              subtitle: const Text('Tap to use GPS location'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home Address'),
              subtitle: const Text('Dar es Salaam, Tanzania'),
              trailing: const Icon(Icons.check_circle, color: AppTheme.primaryTeal),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: AppTheme.primaryTeal),
              title: const Text('Add New Address', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
