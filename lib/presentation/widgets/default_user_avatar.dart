import 'package:flutter/material.dart';

/// Avatar por defecto del jugador (drawer, perfil, etc.).
class DefaultUserAvatar extends StatelessWidget {
  const DefaultUserAvatar({super.key, this.radius = 40});

  final double radius;

  static const String imageUrl =
      'https://www.pngall.com/wp-content/uploads/5/Profile-PNG-High-Quality-Image.png';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: const NetworkImage(imageUrl),
    );
  }
}
