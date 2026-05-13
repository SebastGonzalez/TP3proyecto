import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/core/menu/menu_item.dart';
import 'package:prueba1/presentation/providers/coin_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {

    int coins = ref.watch(coinProvider);  

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),

      drawer: _MenuDrawer(coins: coins),
  
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Coins: $coins', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Conseguí más monedas en la Tienda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
      
    );
  }
}

class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({
    required this.coins,
  });

  final int coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) { 

    List<MenuItem> getMenuItems() {
      return menuItems;
    }
    List<MenuItem> items = getMenuItems();

    return SafeArea(
      child: NavigationDrawer(
        header: DrawerHeader(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 44,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text('Coins: $coins', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('User Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ),

        children: [
          for (var item in items) 
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              subtitle: Text(item.description),
              onTap: () {
                context.push(item.route);
              },
            ),
            
        ],
      ),
    );
  }
}
