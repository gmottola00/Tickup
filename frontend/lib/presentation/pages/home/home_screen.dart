import 'package:flutter/material.dart';

/// Schermata principale con benvenuto e link a Pools
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SkillWin Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/pool'),
          child: Text('Vai ai giochi'),
        ),
      ),
    );
  }
}
