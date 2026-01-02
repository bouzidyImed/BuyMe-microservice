import 'package:flutter/material.dart';
import 'home_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse HomeScreen for shop functionality (same product listing + filters)
    return const HomeScreen();
  }
}
