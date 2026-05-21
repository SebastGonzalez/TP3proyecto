import 'package:flutter/material.dart';

/// Una entrada navegable del menú lateral.
class MenuItem {
  const MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

/// Grupo de entradas bajo un mismo título en el drawer.
class MenuSection {
  const MenuSection({
    required this.label,
    required this.items,
  });

  final String label;
  final List<MenuItem> items;
}

/// Definición central del menú: una sola fuente de verdad por sección.
const List<MenuSection> appMenuSections = [
  MenuSection(
    label: 'COLECCIÓN',
    items: [
      MenuItem(
        title: 'Mis monstruos',
        subtitle: 'Monstruos que capturaste',
        icon: Icons.pets,
        route: '/mymonsters',
      ),
      MenuItem(
        title: 'Pokédex',
        subtitle: 'Catálogo completo',
        icon: Icons.menu_book_outlined,
        route: '/pokedex',
      ),
    ],
  ),
  MenuSection(
    label: 'AVENTURA',
    items: [
      MenuItem(
        title: 'Gatcha',
        subtitle: 'Invocar nuevos monstruos',
        icon: Icons.casino_outlined,
        route: '/gatcha',
      ),
      MenuItem(
        title: 'Fusión',
        subtitle: 'Sacrificios y recompensas',
        icon: Icons.auto_awesome_outlined,
        route: '/sacrifice',
      ),
      MenuItem(
        title: 'Minijuego',
        subtitle: 'Ganá monedas jugando',
        icon: Icons.videogame_asset_outlined,
        route: '/game',
      ),
    ],
  ),
  MenuSection(
    label: 'COMERCIO',
    items: [
      MenuItem(
        title: 'Intercambio',
        subtitle: 'Canjeá con tus amigos',
        icon: Icons.storefront_outlined,
        route: '/market',
      ),
      MenuItem(
        title: 'Tienda',
        subtitle: 'Compra monedas y mejoras',
        icon: Icons.shopping_cart_outlined,
        route: '/shop',
      ),
    ],
  ),
];

/// Lista plana (útil si algún código legacy la necesita).
List<MenuItem> get allMenuItems => [
      for (final section in appMenuSections) ...section.items,
    ];
