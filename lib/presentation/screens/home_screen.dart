import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/coin_provider.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';
import 'package:prueba1/presentation/providers/drawer_navigation_provider.dart';
import 'package:prueba1/presentation/widgets/app_drawer.dart';
import 'package:prueba1/presentation/providers/mymonster_provider.dart';
import 'package:prueba1/presentation/providers/trade_provider.dart';
import 'package:prueba1/presentation/widgets/coins_badge.dart';
import 'package:prueba1/presentation/widgets/gatcha_reveal.dart';

/// Cuánto se corre el personaje a la derecha si hay compañero (fracción del ancho del PJ).
const _kHomeShiftWithCompanionFactor = 0.08;

const _kHomeGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF7EC8E3), Color(0xFFE8F4EA)],
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _tradeCheckDone = false;

  void _openDrawerIfRequested() {
    if (!ref.read(reopenDrawerOnHomeProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scaffoldKey.currentState?.openDrawer();
      ref.read(reopenDrawerOnHomeProvider.notifier).state = false;
    });
  }

  Future<void> _checkUnseenTrades() async {
    if (_tradeCheckDone) return;
    _tradeCheckDone = true;

    final unseen = await ref.read(unseenCompletedTradesProvider.future);
    if (unseen.isEmpty || !mounted) return;

    final catalog = await ref.read(monstersProvider.future);

    for (final trade in unseen) {
      if (!mounted) return;
      final monsterId = trade.receivedMonsterId;
      if (monsterId == null) continue;

      final received = catalog.where((m) => m.id == monsterId).firstOrNull;
      if (received != null && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.swap_horiz, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text('Trade exitoso'),
              ],
            ),
            content: Text(
              'Mientras estabas fuera, tu intercambio se completó.\n\n'
              'Recibiste: ${received.name}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Ver monstruo'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        await showGatchaReveal(context, received);
      }

      await ref.read(tradeRepositoryProvider).markSeen(trade.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reopenDrawerOnHomeProvider, (previous, next) {
      if (next == true) _openDrawerIfRequested();
    });

    ref.listen(unseenCompletedTradesProvider, (_, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        _checkUnseenTrades();
      }
    });

    ref.watch(authUsernameBootstrapProvider);
    final coins = ref.watch(coinProvider);
    final username = ref.watch(currentUsernameProvider);
    final companion = ref.watch(homeCompanionViewProvider);
    final companionTint = companion?.backgroundColor;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: _kHomeGradient)),
          if (companionTint != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    companionTint.withValues(alpha: 0.38),
                    companionTint.withValues(alpha: 0.14),
                    companionTint.withValues(alpha: 0.04),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          SafeArea(
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
                          username: username,
                          compact: compact,
                          maxImageHeight: constraints.maxHeight * 0.48,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _HomeTopBar(
                        coins: coins,
                        onMenuPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.coins,
    required this.onMenuPressed,
  });

  final int coins;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D4A5E)),
            onPressed: onMenuPressed,
          ),
          const Spacer(),
          CoinsBadge(coins: coins),
        ],
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
    final companion = ref.watch(homeCompanionViewProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.62;
        final onLeft = companion?.side != HomeCompanionSide.right;
        final companionWidth =
            imageWidth * 1.05 * (companion?.scale ?? 1);
        final shiftX = companion == null
            ? 0.0
            : (onLeft ? 1 : -1) *
                imageWidth *
                _kHomeShiftWithCompanionFactor;

        return Transform.translate(
          offset: Offset(shiftX, 0),
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
                            left: onLeft ? -imageWidth * 0.42 : null,
                            right: onLeft ? null : -imageWidth * 0.42,
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
