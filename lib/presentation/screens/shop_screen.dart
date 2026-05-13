import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/presentation/providers/coin_provider.dart';

/// Paquete de monedas vendido en el mercado (precio solo demostración).
class _CoinOffer {
  const _CoinOffer({required this.coins, required this.priceLabel});

  final int coins;
  final String priceLabel;
}

const List<_CoinOffer> _offers = [
  _CoinOffer(coins: 250, priceLabel: r'$ 0,99'),
  _CoinOffer(coins: 500, priceLabel: r'$ 1,49'),
  _CoinOffer(coins: 1000, priceLabel: r'$ 2,49'),
  _CoinOffer(coins: 2000, priceLabel: r'$ 4,49'),
  _CoinOffer(coins: 5000, priceLabel: r'$ 9,99'),
];

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _messenger?.clearSnackBars();
    super.dispose();
  }

  void _buy(int coins) {
    ref.read(coinProvider.notifier).update((state) => state + coins);
  }

  /// Una sola notificación a la vez; al salir de la tienda no queda cola.
  void _showPurchaseSnack(int coins) {
    final messenger = _messenger;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Compra simulada: +$coins monedas'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _ShopCoinsBadge(coins: coins),
          const SizedBox(height: 20),
          Text(
            'Mercado de monedas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Comprá paquetes con un pago simulado (sin cargo real). '
            'Al tocar Comprar se acreditan las monedas al instante.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          ..._offers.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OfferCard(
                offer: offer,
                accent: scheme.primary,
                onBuy: () {
                  _buy(offer.coins);
                  _showPurchaseSnack(offer.coins);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCoinsBadge extends StatelessWidget {
  const _ShopCoinsBadge({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              '$coins',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.accent,
    required this.onBuy,
  });

  final _CoinOffer offer;
  final Color accent;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Icon(
                Icons.monetization_on,
                color: Colors.amber.shade800,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${offer.coins} monedas',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        offer.priceLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(demo)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onBuy,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Comprar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
