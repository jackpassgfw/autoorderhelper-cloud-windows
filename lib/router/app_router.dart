import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_notifier.dart';
import '../features/auth/login_page.dart';
import '../features/auto_orders/auto_orders_page.dart';
import '../features/business_centers/business_centers_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/cart/cart_page.dart';
import '../features/categories/categories_page.dart';
import '../features/countries/countries_page.dart';
import '../features/customers/customers_page.dart';
import '../features/previews/previews_page.dart';
import '../features/products/products_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final loggedIn = authState.isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) {
        return '/login';
      }
      if (loggedIn && loggingIn) {
        return '/previews';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const MaterialPage(child: LoginPage()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(path: '/', redirect: (context, state) => '/previews'),
          GoRoute(
            path: '/customers',
            name: 'customers',
            pageBuilder: (context, state) =>
                const MaterialPage(child: CustomersPage()),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            pageBuilder: (context, state) =>
                const MaterialPage(child: ProductsPage()),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            pageBuilder: (context, state) =>
                const MaterialPage(child: CartPage()),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) =>
                const MaterialPage(child: CategoriesPage()),
          ),
          GoRoute(
            path: '/countries',
            name: 'countries',
            pageBuilder: (context, state) =>
                const MaterialPage(child: CountriesPage()),
          ),
          GoRoute(
            path: '/auto-orders',
            name: 'auto-orders',
            pageBuilder: (context, state) =>
                const MaterialPage(child: AutoOrdersPage()),
          ),
          GoRoute(
            path: '/business-centers',
            name: 'business-centers',
            pageBuilder: (context, state) =>
                const MaterialPage(child: BusinessCentersPage()),
          ),
          GoRoute(
            path: '/previews',
            name: 'previews',
            pageBuilder: (context, state) =>
                const MaterialPage(child: PreviewsPage()),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            pageBuilder: (context, state) =>
                const MaterialPage(child: CalendarPage()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                const MaterialPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
