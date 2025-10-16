import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/providers/navigation_provider.dart';

class ModernBottomNavigation extends ConsumerWidget {
  const ModernBottomNavigation({super.key});

  static const _destinations = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: AppRoute.home,
    ),
    (
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports,
      label: 'Giochi',
      route: AppRoute.games,
    ),
    (
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Profilo',
      route: AppRoute.profile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    int detectedIndex = -1;
    for (var i = 0; i < _destinations.length; i++) {
      final route = _destinations[i].route;
      final isMatch = _matchesRoute(location, route);
      if (isMatch) {
        detectedIndex = i;
      }
    }

    final previousIndex = ref.watch(currentTabIndexProvider);
    final fallbackIndex = (previousIndex >= 0 && previousIndex < _destinations.length)
        ? previousIndex
        : 0;
    final selectedIndex = detectedIndex >= 0 ? detectedIndex : fallbackIndex;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Aggiorna il provider dell'indice corrente
    if (detectedIndex >= 0 && detectedIndex != previousIndex) {
      Future.microtask(() {
        ref.read(currentTabIndexProvider.notifier).state = detectedIndex;
      });
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: NavigationBar(
          height: 75,
          backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            final destination = _destinations[index];
            final isAlreadyOnDestination = _matchesRoute(location, destination.route);
            if (!isAlreadyOnDestination) {
              context.go(destination.route);
            }
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationDestination(
                icon: _buildNavItem(
                  icon: _destinations[i].icon,
                  activeIcon: _destinations[i].activeIcon,
                  isSelected: selectedIndex == i,
                  color: theme.colorScheme.primary,
                  isDarkMode: isDarkMode,
                ),
                label: _destinations[i].label,
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesRoute(String location, String route) {
    if (route == AppRoute.home || route == '/') {
      return location == AppRoute.home || location == '/' || location.isEmpty;
    }
    return location == route ||
        location.startsWith('$route/') ||
        location.startsWith('$route?');
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required Color color,
    required bool isDarkMode,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(isSelected ? 8 : 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isSelected ? activeIcon : icon,
          key: ValueKey(isSelected),
          size: isSelected ? 28 : 24,
          color: isSelected
              ? color
              : isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
        ),
      ),
    );
  }
}
