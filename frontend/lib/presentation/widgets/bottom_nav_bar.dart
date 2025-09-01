import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/providers/navigation_provider.dart';

class ModernBottomNavigation extends ConsumerWidget {
  const ModernBottomNavigation({super.key});

  static const _destinations = [
    (
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports,
      label: 'Giochi',
      route: AppRoute.games,
      color: Color(0xFF6366F1),
    ),
    (
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Premi',
      route: AppRoute.prizes,
      color: Color(0xFFF59E0B),
    ),
    (
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard,
      label: 'Classifica',
      route: AppRoute.leaderboard,
      color: Color(0xFF10B981),
    ),
    (
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Profilo',
      route: AppRoute.profile,
      color: Color(0xFF8B5CF6),
    ),
  ];

  int _getSelectedIndex(String location) {
    for (int i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Aggiorna il provider dell'indice corrente
    Future.microtask(() {
      ref.read(currentTabIndexProvider.notifier).state = selectedIndex;
    });

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
            if (index != selectedIndex) {
              context.go(_destinations[index].route);
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
                  color: _destinations[i].color,
                  isDarkMode: isDarkMode,
                ),
                label: _destinations[i].label,
              ),
          ],
        ),
      ),
    );
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
