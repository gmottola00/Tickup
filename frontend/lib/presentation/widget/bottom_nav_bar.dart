import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  static const _destinations = [
    (icon: Icons.home_outlined, label: 'Giochi', route: AppRoute.dashboard),
    (icon: Icons.person_outline, label: 'Profilo', route: AppRoute.register),
    (icon: Icons.card_giftcard_outlined, label: 'Premi', route: AppRoute.prize),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex =
        _destinations.indexWhere((d) => location.startsWith(d.route));

    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => context.go(_destinations[index].route),
      destinations: [
        for (final d in _destinations)
          NavigationDestination(icon: Icon(d.icon), label: d.label),
      ],
    );
  }
}
