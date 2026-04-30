import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/product_detail_page.dart';
import '../features/home/presentation/pages/search_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/healthcare/presentation/pages/healthcare_page.dart';
import '../features/healthcare/presentation/pages/telemedicine_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/cart/presentation/pages/checkout_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/home/presentation/pages/patient_appointments_page.dart';
import '../features/home/presentation/pages/patient_orders_page.dart';
import '../features/profile/presentation/pages/settings_page.dart';
import '../features/healthcare/presentation/pages/labs_page.dart';
import '../features/healthcare/presentation/pages/pharmacies_page.dart';
import '../features/healthcare/presentation/pages/doctor_detail_page.dart';
import '../features/appointments/presentation/pages/chat_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'product/:id',
            builder: (context, state) => ProductDetailPage(idOrSlug: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: 'cart',
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: 'checkout',
            builder: (context, state) => const CheckoutPage(),
          ),
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignupPage(),
          ),
          GoRoute(
            path: 'appointments',
            builder: (context, state) => const PatientAppointmentsPage(),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const PatientOrdersPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'telemedicine',
            builder: (context, state) => const TelemedicinePage(),
          ),
          GoRoute(
            path: 'healthcare',
            builder: (context, state) => const HealthcarePage(),
          ),
          GoRoute(
            path: 'pharmacies',
            builder: (context, state) => const PharmaciesPage(),
          ),
          GoRoute(
            path: 'labs',
            builder: (context, state) => const LabsPage(),
          ),
          GoRoute(
            path: 'doctor/:id',
            builder: (context, state) => DoctorDetailPage(doctorId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'chat/:id',
            builder: (context, state) => ChatPage(appointmentId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
