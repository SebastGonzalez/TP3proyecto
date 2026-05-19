import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/core/menu/menu_item.dart';
import 'package:prueba1/presentation/providers/coin_provider.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';

/// Mismo placeholder que en perfil hasta haber auth real.
const _kUsername = 'User Name';

/// Cuánto se corre el personaje a la derecha si hay compañero (fracción del ancho del PJ).
const _kHomeShiftWithCompanionFactor = 0.08;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinProvider);

    return Scaffold(
      drawer: _MenuDrawer(coins: coins),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7EC8E3),
              Color(0xFFB8E6F5),
              Color(0xFFE8F4EA),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _CharacterHub(
                        username: _kUsername,
                        compact: compact,
                        maxImageHeight: constraints.maxHeight * 0.48,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _HomeTopBar(coins: coins),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D4A5E)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const Spacer(),
          _CoinChip(coins: coins),
        ],
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    // Material: capa base del diseño Material; InkWell necesita un ancestro
    // Material para dibujar el efecto ripple al tocar.
    return Material(
      color: Colors.transparent,
      // InkWell: detecta tap y muestra ripple (alternativa: GestureDetector, sin ripple).
      child: InkWell(
        onTap: () => context.push('/shop'),
        borderRadius: BorderRadius.circular(20),
        // Ink: pinta el fondo del chip; el ripple de InkWell se dibuja encima.
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6B800), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on_rounded,
                    size: 18, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterHub extends ConsumerWidget {
  const _CharacterHub({
    required this.username,
    required this.compact,
    required this.maxImageHeight,
  });

  final String username;
  final bool compact;
  final double maxImageHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = ref.watch(homeCompanionVisibleProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.62;
        final companionWidth = imageWidth * 1.05;
        final shiftRight = companion != null
            ? imageWidth * _kHomeShiftWithCompanionFactor
            : 0.0;

        return Transform.translate(
          offset: Offset(shiftRight, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxImageHeight),
                child: Center(
                  child: SizedBox(
                    width: imageWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        if (companion != null)
                          Positioned(
                            left: -imageWidth * 0.42,
                            bottom: 0,
                            child: Image.asset(
                              companion.imagePath,
                              width: companionWidth,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            'assets/images/personaje.png',
                            width: imageWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¡Hola, $username!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A4F),
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuDrawer extends ConsumerWidget {
  const _MenuDrawer({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = menuItems;

    return SafeArea(
      child: NavigationDrawer(
        header: DrawerHeader(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 44,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Coins: $coins',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Text(
                _kUsername,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Logout'),
          ),
        ),
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              subtitle: Text(item.description),
              onTap: () => context.push(item.route),
            ),
        ],
      ),
    );
  }
}
