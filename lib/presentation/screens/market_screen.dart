import 'package:flutter/material.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Mercado'),
      body: const Center(
        child: Text('Welcome to the Market!'),
      ),
    );
  }
}