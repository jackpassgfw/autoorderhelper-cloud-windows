import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_notifier.dart';
import '../auto_orders/auto_orders_notifier.dart';
import '../business_centers/business_centers_notifier.dart';
import '../cart/cart_notifier.dart';
import '../categories/categories_notifier.dart';
import '../customers/customer_auto_orders_notifier.dart';
import '../customers/customer_followups_notifier.dart';
import '../customers/customers_notifier.dart';
import '../previews/previews_notifier.dart';
import '../products/products_notifier.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static final _destinations = <_NavDestination>[
    _NavDestination(
      path: '/customers',
      label: 'Customers',
      icon: Icons.people_alt_outlined,
    ),
    _NavDestination(
      path: '/products',
      label: 'Products',
      icon: Icons.inventory_2_outlined,
    ),
    _NavDestination(
      path: '/cart',
      label: 'Cart',
      icon: Icons.shopping_cart_outlined,
    ),
    _NavDestination(
      path: '/categories',
      label: 'Categories',
      icon: Icons.category_outlined,
    ),
    _NavDestination(
      path: '/auto-orders',
      label: 'Auto Orders',
      icon: Icons.event_repeat_outlined,
    ),
    _NavDestination(
      path: '/business-centers',
      label: 'Business Centers',
      icon: Icons.apartment_outlined,
    ),
    _NavDestination(
      path: '/previews',
      label: 'Next-Week',
      icon: Icons.calendar_view_week_outlined,
    ),
    _NavDestination(
      path: '/calendar',
      label: '4-week Calendar',
      icon: Icons.view_week_outlined,
    ),
    _NavDestination(
      path: '/settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _destinations.indexWhere(
      (d) => location == d.path || location.startsWith('${d.path}/'),
    );
    final cartState = ref.watch(cartNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Order Helper'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  'Logout',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
            onDestinationSelected: (index) {
              final destination = _destinations[index];
              context.go(destination.path);
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: _buildNavIcon(
                    destination,
                    cartState.itemCount,
                    Theme.of(context).colorScheme,
                  ),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final IconData icon;
}

Widget _buildNavIcon(
  _NavDestination destination,
  int cartCount,
  ColorScheme colorScheme,
) {
  if (destination.path != '/cart' || cartCount == 0) {
    return Icon(destination.icon);
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(destination.icon),
      Positioned(
        right: -6,
        top: -4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            cartCount > 99 ? '99+' : cartCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  await ref.read(authNotifierProvider.notifier).logout();
  await _clearRememberedCredentials();
  _resetFeatureState(ref);
  if (!context.mounted) {
    return;
  }
  context.go('/login');
}

Future<void> _clearRememberedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('remember_me');
  await prefs.remove('remember_email');
  await prefs.remove('remember_password');
}

void _resetFeatureState(WidgetRef ref) {
  ref.invalidate(autoOrdersNotifierProvider);
  ref.invalidate(businessCentersNotifierProvider);
  ref.invalidate(cartNotifierProvider);
  ref.invalidate(categoriesNotifierProvider);
  ref.invalidate(customersNotifierProvider);
  ref.invalidate(productsNotifierProvider);
  ref.invalidate(customerAutoOrdersProvider);
  ref.invalidate(customerFollowupsProvider);
  ref.invalidate(previewsNotifierProvider);
}
