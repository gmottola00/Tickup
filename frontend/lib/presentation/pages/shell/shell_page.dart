import 'package:flutter/material.dart';
import 'package:tickup/presentation/widget/bottom_nav_bar.dart';

class ShellPage extends StatelessWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: const BottomNavigation(),
    );
  }
}
