import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/gatcha/application/controllers/gatcha_roll_controller_provider.dart';
import 'package:prueba1/features/gatcha/application/providers/gatcha_machines_provider.dart';
import 'package:prueba1/features/gatcha/domain/gatcha_machine.dart';
import 'package:prueba1/features/gatcha/domain/roll_strategy.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';
import 'package:prueba1/features/shop/application/providers/coin_provider.dart';
import 'package:prueba1/features/shop/presentation/widgets/coins_badge.dart';
import 'package:prueba1/features/monsters/application/providers/mymonster_provider.dart';
import 'package:prueba1/features/monsters/application/providers/owned_monsters_provider.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';
import 'package:prueba1/presentation/widgets/gatcha_reveal.dart';

class GatchaScreen extends ConsumerStatefulWidget {
  const GatchaScreen({super.key});

  @override
  ConsumerState<GatchaScreen> createState() => _GatchaScreenState();
}

class _GatchaScreenState extends ConsumerState<GatchaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshMonstersCatalog(ref);
      ref.invalidate(gatchaMachinesProvider);
      ref.invalidate(ownedMonstersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(coinProvider);
    final monstersAsync = ref.watch(monstersProvider);
    final machinesAsync = ref.watch(gatchaMachinesProvider);

    return Scaffold(
      appBar: const AppPageAppBar(title: 'Gatcha Machines'),
      body: monstersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando monstruos: $e')),
        data: (monsters) => machinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error cargando máquinas: $e')),
          data: (machines) => _GatchaBody(
            coins: coins,
            monsters: monsters,
            machines: machines,
          ),
        ),
      ),
    );
  }
}

class _GatchaBody extends ConsumerStatefulWidget {
  const _GatchaBody({
    required this.coins,
    required this.monsters,
    required this.machines,
  });

  final int coins;
  final List<Monster> monsters;
  final List<GatchaMachine> machines;

  @override
  ConsumerState<_GatchaBody> createState() => _GatchaBodyState();
}

class _GatchaBodyState extends ConsumerState<_GatchaBody>
    with SingleTickerProviderStateMixin {
  static final Random _rng = Random();

  late final AnimationController _idleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  final PageController _pageCtrl = PageController(viewportFraction: 0.85);

  int _currentIndex = 0;
  bool _rolling = false;

  @override
  void dispose() {
    _idleCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRoll(GatchaMachine machine) async {
    if (_rolling) return;

    final controller = ref.read(gatchaRollControllerProvider);
    final message = controller.validate(
      machine: machine,
      monsters: widget.monsters,
      coins: widget.coins,
    );
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    setState(() => _rolling = true);
    final result = await controller.roll(
      machine: machine,
      monsters: widget.monsters,
      coins: widget.coins,
      rng: _rng,
    );

    if (!mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
      setState(() => _rolling = false);
      return;
    }

    for (final monster in result.created) {
      await showGatchaReveal(context, monster);
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() => _rolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final machines = widget.machines;
    if (machines.isEmpty) {
      return const Center(child: Text('No hay máquinas disponibles'));
    }
    final safeIndex = _currentIndex.clamp(0, machines.length - 1);
    final machine = machines[safeIndex];
    final canAfford = widget.coins >= machine.cost && !_rolling;

    return Stack(
      children: [
        // Halo ambiental de fondo: sale del centro y se difumina antes
        // de tocar los bordes. Cambia de color al cambiar de máquina.
        Positioned.fill(
          child: IgnorePointer(
            child: _BackgroundHalo(color: machine.haloColor),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 12),
            CoinsBadge(coins: widget.coins),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: machines.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, i) {
                  return AnimatedBuilder(
                    animation: _pageCtrl,
                    builder: (context, child) {
                      double t = 1.0;
                      if (_pageCtrl.position.haveDimensions) {
                        final page = _pageCtrl.page ?? safeIndex.toDouble();
                        t = (1 - ((page - i).abs() * 0.18)).clamp(0.0, 1.0);
                      } else if (i != safeIndex) {
                        t = 0.85;
                      }
                      return Transform.scale(scale: t, child: child);
                    },
                    child: _MachinePage(
                      machine: machines[i],
                      idleCtrl: _idleCtrl,
                      unlocked: widget.coins >= machines[i].cost,
                    ),
                  );
                },
              ),
            ),
            _PageDots(
              count: machines.length,
              current: safeIndex,
              activeColor: machine.haloColor,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canAfford ? () => _onRoll(machine) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: machine.accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.casino),
                  label: Text(
                    _rolling
                        ? 'Tirando...'
                        : machine.rollsPerPull > 1
                            ? 'Roll ×${machine.rollsPerPull} ${machine.name} (${machine.cost} coins)'
                            : 'Roll ${machine.name} (${machine.cost} coins)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            if (!canAfford && !_rolling)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Necesitás ${machine.cost} monedas',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

/// Halo radial que ocupa la zona central de la pantalla y se desvanece
/// hacia los bordes. No llena toda la pantalla: el `radius` lo deja
/// concentrado en el medio. Anima el color al cambiar de máquina.
class _BackgroundHalo extends StatelessWidget {
  const _BackgroundHalo({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      tween: ColorTween(end: color),
      builder: (context, animatedColor, _) {
        final c = animatedColor ?? color;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.05),
              radius: 0.65,
              colors: [
                c.withOpacity(0.35),
                c.withOpacity(0.12),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Página de cada máquina dentro del carousel
// ---------------------------------------------------------------------------

class _MachinePage extends StatelessWidget {
  const _MachinePage({
    required this.machine,
    required this.idleCtrl,
    required this.unlocked,
  });

  final GatchaMachine machine;
  final AnimationController idleCtrl;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Text(
            machine.name.toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: machine.accentColor,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            machine.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Center(
              child: _IdleMachine(
                controller: idleCtrl,
                haloColor: machine.haloColor,
              ),
            ),
          ),
          _RarityRates(strategy: machine.strategy),
          if (machine.rollsPerPull > 1) ...[
            const SizedBox(height: 8),
            Text(
              '${machine.rollsPerPull} monstruos por tirada',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: machine.accentColor.withOpacity(0.85),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: machine.accentColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: machine.accentColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${machine.cost}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: machine.accentColor,
                  ),
                ),
              ],
            ),
          ),
          if (!unlocked)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Sin monedas',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini display de los multiplicadores por rareza
// ---------------------------------------------------------------------------

/// Muestra % por rareza ([RarityRatesInfo]).
class _RarityRates extends StatelessWidget {
  const _RarityRates({required this.strategy});
  final RollStrategy strategy;

  @override
  Widget build(BuildContext context) {
    if (strategy is! RarityRatesInfo) return const SizedBox.shrink();
    final rates = (strategy as RarityRatesInfo).rarityRatesPercent;
    if (rates.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final e in rates.entries)
          _RarityChip(
            rarity: e.key,
            highlighted: e.value >= 10,
            rateText: '${e.value.round()}%',
          ),
      ],
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.rarity,
    required this.highlighted,
    required this.rateText,
  });

  final Rarity rarity;
  final bool highlighted;
  final String rateText;

  @override
  Widget build(BuildContext context) {
    final color = rarity.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(highlighted ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(highlighted ? 0.6 : 0.2),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rarity.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rateText,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Imagen central de la máquina con halo + flotación
// ---------------------------------------------------------------------------

class _IdleMachine extends StatelessWidget {
  const _IdleMachine({required this.controller, required this.haloColor});
  final AnimationController controller;
  final Color haloColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final dy = sin(t * pi * 2) * 6;
        // Glow propio sutil (el halo grande lo da el fondo del Scaffold).
        final glow = 0.18 + 0.22 * t;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: haloColor.withOpacity(glow),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/Gatcha.png',
              height: 240,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Indicadores de página (dots)
// ---------------------------------------------------------------------------

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
    required this.activeColor,
  });

  final int count;
  final int current;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
