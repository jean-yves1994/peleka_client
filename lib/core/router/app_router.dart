import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/auth_view_model.dart';
import '../../features/home/home_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/shipments/presentation/shipments_list_screen.dart';
import '../../features/shipments/presentation/shipment_detail_screen.dart';
import '../../features/shipments/presentation/create_shipment_screen.dart';
import '../../features/shipments/presentation/quote_review_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/notifications/notifications_screen.dart';
// ⭐ Payment screen (Flutterwave checkout)
import '../../features/payments/presentation/payment_screen.dart';

/// Router is built ONCE and never recreated (no `ref.watch` here — that would
/// rebuild GoRouter on every auth change and snap back to /splash).
/// `refreshListenable` re-runs `redirect`, which is the single source of truth.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RiverpodListenable(ref, authViewModelProvider),

    // Friendly fallback instead of a raw GoException screen.
    errorBuilder: (context, state) => _RouteErrorScreen(location: state.uri.toString()),

    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);
      final loc = state.matchedLocation;
      const authRoutes = ['/login', '/register', '/otp', '/onboarding'];
      final isAuthRoute = authRoutes.contains(loc);
      final onSplash = loc == '/splash';

      // Treat "/" as home so a stray root navigation never 404s.
      if (loc == '/') {
        return auth.status == AuthStatus.authenticated ? '/home' : '/login';
      }

      // 1) Still bootstrapping → hold on splash.
      if (auth.status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }
      // 2) Signed in → never sit on splash/auth screens.
      if (auth.status == AuthStatus.authenticated) {
        if (onSplash || isAuthRoute) return '/home';
        return null;
      }
      // 3) Signed out → leave splash for onboarding/login; protect the rest.
      if (onSplash) return auth.onboardingSeen ? '/login' : '/onboarding';
      if (!isAuthRoute) return '/login';
      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, s) => OtpScreen(phone: s.uri.queryParameters['phone'] ?? ''),
      ),

      // Bottom-nav shell
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/shipments', builder: (_, __) => const ShipmentsListScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Full-screen flows
      GoRoute(path: '/shipments/create', builder: (_, __) => const CreateShipmentScreen()),
      GoRoute(path: '/shipments/quote', builder: (_, __) => const QuoteReviewScreen()),

      // ⭐ PAYMENT ROUTE — this is what was missing.
      // Query params are read case-sensitively, so we accept both spellings
      // (`shipmentId` and `shipmentid`) to be forgiving of typos in callers.
      GoRoute(
        path: '/pay',
        builder: (_, s) {
          final q = s.uri.queryParameters;
          final shipmentId = q['shipmentId'] ?? q['shipmentid'] ?? '';
          final tracking = q['trackingNumber'] ?? q['trackingnumber'] ?? '';
          return PaymentScreen(shipmentId: shipmentId, trackingNumber: tracking);
        },
      ),

      GoRoute(
        path: '/shipments/:id',
        builder: (_, s) => ShipmentDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shipments/:id/track',
        builder: (_, s) => TrackingScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
});

class _RiverpodListenable extends ChangeNotifier {
  _RiverpodListenable(this._ref, this._provider) {
    _ref.listen(_provider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  final ProviderListenable _provider;
}

/// Shown instead of a raw GoException if navigation ever hits an unknown path.
class _RouteErrorScreen extends StatelessWidget {
  final String location;
  const _RouteErrorScreen({required this.location});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Color(0xFFFF8508)),
              const SizedBox(height: 16),
              const Text('We could not open that screen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF08295D))),
              const SizedBox(height: 8),
              Text(location,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Go home'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8508)),
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
