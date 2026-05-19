import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  

  MenuItem({required this.title, required this.description, required this.icon, required this.route});


  List<MenuItem> getMenuItems() {
    return menuItems;
  }
}

final List<MenuItem> menuItems = [
  /*
  MenuItem(
    title: 'Profile',
    description: 'View your profile',
    icon: Icons.person,
    route: '/profile',
  ),
  */
  MenuItem(
    title: 'My Monsters',
    description: 'View your monsters',
    icon: Icons.pets,
    route: '/mymonsters',
  ),
  MenuItem(
    title: 'Pokedex',
    description: 'Go to the pokedex',
    icon: Icons.book,
    route: '/pokedex',
  ),
  MenuItem(
    title: 'Gatcha',
    description: 'Summon new monsters',
    icon: Icons.casino,
    route: '/gatcha',
  ),
  MenuItem(
    title: 'Fusion',
    description: 'Sacrifice monsters for rewards',
    icon: Icons.adf_scanner,
    route: '/sacrifice',
  ),
  MenuItem(
    title: 'Shop',
    description: 'Buy items for your monsters',
    icon: Icons.shopping_cart,
    route: '/shop',
  ),
  MenuItem(
    title: 'Settings',
    description: 'Adjust your preferences',
    icon: Icons.settings,
    route: '/settings',
  ),
];