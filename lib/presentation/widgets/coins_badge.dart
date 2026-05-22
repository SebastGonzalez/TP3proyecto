import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Color del icono y del monto (compartido con textos de monedas en la tienda).
Color get coinsAccentColor => Colors.amber.shade800;

/// Chip de saldo de monedas. Por defecto abre `/shop` al tocar.
class CoinsBadge extends StatelessWidget {
  const CoinsBadge({
    super.key,
    required this.coins,
    this.onTap,
    this.linkToShop = true,
    this.centered = false,
  });

  final int coins;

  /// Si [linkToShop] es true y [onTap] es null, navega a `/shop`.
  final VoidCallback? onTap;
  final bool linkToShop;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final tap = onTap ??
        (linkToShop ? () => context.push('/shop') : null);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: coinsAccentColor, size: 20),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: coinsAccentColor,
            ),
          ),
        ],
      ),
    );

    final Widget badge;
    if (tap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(30),
          child: content,
        ),
      );
    } else {
      badge = content;
    }

    if (centered) return Center(child: badge);
    return badge;
  }
}
