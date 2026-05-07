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
            Text('Coins: $coins'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(coinProvider.notifier).state++;
              },
              child: Text('Increment Coins'),
            ),
          ],
        ),
      ),
      
    );
  }
}

class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({
    super.key,
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
                  backgroundImage: Image.network( 'https://www.pngall.com/wp-content/uploads/5/Profile-PNG-High-Quality-Image.png').image,
                ),
              ),
              SizedBox(height: 10),
              Text('Coins: $coins', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('User Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        footer: ButtonTheme(child:  ElevatedButton(
          onPressed: () {
            context.go('/login');
          },
          child: Text('Logout'),
        )),

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
