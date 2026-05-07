import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/presentation/providers/coin_provider.dart';

class GatchaScreen extends ConsumerWidget {
  
  const GatchaScreen({super.key});

  @override
  Widget build(BuildContext context,  ref) {
    int coins = ref.watch(coinProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gatcha Screen'),
      ),
      body: _body(coins: coins),
    );
  }
}

class _body extends ConsumerWidget {
  const _body({super.key, this.coins = 0});

  final int coins;  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text( 'Coins: $coins'),
          Image.asset('assets/images/Gatcha.png', ),
          SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {
              // Implement gatcha logic here
              if (coins >= 500) {
                // Deduct coins and perform gatcha roll
                ref.read(coinProvider.notifier).update((state) => state - 500);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gatcha rolled!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Not enough coins!')),
                );
              }
              
            },
            child: Text('Roll Gatcha (500 Coins)'),
          ),
        ],
      ),
    );
  }
}