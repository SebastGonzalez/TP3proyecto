import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';

/// Abre la animación full-screen de "tirado de gatcha" con la pokébola + carta
/// del monstruo obtenido. Tap salta a la carta; tap de nuevo cierra.
Future<void> showGatchaReveal(BuildContext context, Monster monster) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => GatchaRevealOverlay(monster: monster),
    ),
  );
}

class GatchaRevealOverlay extends StatefulWidget {
  const GatchaRevealOverlay({super.key, required this.monster});

  final Monster monster;

  @override
  State<GatchaRevealOverlay> createState() => _GatchaRevealOverlayState();
}

class _GatchaRevealOverlayState extends State<GatchaRevealOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ballCtrl; // entrada de la pokébola
  late final AnimationController _shakeCtrl; // 3 sacudidas
  late final AnimationController _flashCtrl; // flash blanco
  late final AnimationController _cardCtrl; // entrada de la carta
  late final AnimationController _shineCtrl; // brillo holográfico en loop

  bool _showCard = false;
  bool _canDismiss = false;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _ballCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _ballCtrl.forward();
    if (!mounted || _skipped) return;
    await _shakeCtrl.forward();
    if (!mounted || _skipped) return;
    unawaited(_flashCtrl.forward());
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _skipped) return;
    _revealCard(animate: true);
  }

  void _revealCard({required bool animate}) {
    if (!mounted) return;
    setState(() => _showCard = true);
    if (animate) {
      _cardCtrl.forward(from: 0).then((_) {
        if (mounted && !_skipped) setState(() => _canDismiss = true);
      });
    } else {
      _cardCtrl.value = 1;
      setState(() => _canDismiss = true);
    }
  }

  void _skipToCard() {
    if (_skipped && _canDismiss) return;
    _skipped = true;
    _ballCtrl.stop();
    _ballCtrl.value = 1;
    _shakeCtrl.stop();
    _shakeCtrl.value = 1;
    _flashCtrl.stop();
    _flashCtrl.value = 0;
    if (_showCard) {
      _cardCtrl.stop();
      _cardCtrl.value = 1;
      if (!_canDismiss) setState(() => _canDismiss = true);
    } else {
      _revealCard(animate: false);
    }
  }

  void _onTap() {
    if (_canDismiss) {
      Navigator.of(context).pop();
      return;
    }
    _skipToCard();
  }

  @override
  void dispose() {
    _ballCtrl.dispose();
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    _cardCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = widget.monster.rarity.color;
    final isRare = widget.monster.rarity.isAtLeastRare;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _Background(rarityColor: rarityColor, intensity: _showCard ? 1 : 0),
            _RaysBurst(
              animation: _cardCtrl,
              color: rarityColor,
              visible: _showCard && isRare,
            ),
            if (!_showCard) _buildPokeball(),
            _Flash(controller: _flashCtrl),
            if (_showCard) _buildCard(rarityColor, isRare),
            if (!_canDismiss)
              const Positioned(
                bottom: 40,
                child: _PulsingHint(text: 'Tocá para saltar'),
              )
            else
              const Positioned(
                bottom: 40,
                child: _PulsingHint(text: 'Tocá para continuar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokeball() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ballCtrl, _shakeCtrl]),
      builder: (_, __) {
        final drop = Curves.elasticOut.transform(_ballCtrl.value);
        final scale = drop.clamp(0.0, 1.05);
        final dropOffsetY = (1 - _ballCtrl.value) * -260;

        // Sacudidas amortiguadas: 3 ciclos completos.
        final t = _shakeCtrl.value;
        final damping = (1 - t);
        final shakeX = sin(t * pi * 6) * damping * 22;
        final tilt = sin(t * pi * 6) * damping * 0.35;

        return Transform.translate(
          offset: Offset(shakeX, dropOffsetY),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: scale,
              child: const _Pokeball(size: 150),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(Color rarityColor, bool isRare) {
    return AnimatedBuilder(
      animation: Listenable.merge([_cardCtrl, _shineCtrl]),
      builder: (_, __) {
        final t = Curves.easeOutBack.transform(_cardCtrl.value.clamp(0.0, 1.0));
        final scale = (0.4 + 0.6 * t).clamp(0.0, 1.05);
        final opacity = _cardCtrl.value.clamp(0.0, 1.0);
        // Pequeño "tilt" en 3D mientras entra
        final tilt = (1 - t) * 0.6;

        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(tilt * 0.4)
              ..rotateY(tilt * 0.6)
              ..scale(scale),
            child: _MonsterCard(
              monster: widget.monster,
              rarityColor: rarityColor,
              shineValue: _shineCtrl.value,
              isRare: isRare,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo
// ---------------------------------------------------------------------------

class _Background extends StatelessWidget {
  const _Background({required this.rarityColor, required this.intensity});

  final Color rarityColor;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [
            rarityColor.withOpacity(0.10 + 0.35 * intensity),
            Colors.black,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flash blanco
// ---------------------------------------------------------------------------

class _Flash extends StatelessWidget {
  const _Flash({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final v = controller.value;
        if (v == 0) return const SizedBox.shrink();
        final opacity = v < 0.5 ? v * 2 : (1 - v) * 2;
        return IgnorePointer(
          child: Container(color: Colors.white.withOpacity(opacity.clamp(0, 1))),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Rayos de luz girando atrás de la carta (para Rare/Legendary)
// ---------------------------------------------------------------------------

class _RaysBurst extends StatelessWidget {
  const _RaysBurst({
    required this.animation,
    required this.color,
    required this.visible,
  });

  final Animation<double> animation;
  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return IgnorePointer(
          child: Transform.rotate(
            angle: animation.value * pi,
            child: Opacity(
              opacity: animation.value.clamp(0, 1) * 0.6,
              child: CustomPaint(
                size: const Size(600, 600),
                painter: _RaysPainter(color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color.withOpacity(0.35);
    const slices = 12;
    for (var i = 0; i < slices; i++) {
      final a = (i * 2 * pi) / slices;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + cos(a) * size.width,
          center.dy + sin(a) * size.width,
        )
        ..lineTo(
          center.dx + cos(a + 0.18) * size.width,
          center.dy + sin(a + 0.18) * size.width,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// "Tocá para continuar" con leve pulso
// ---------------------------------------------------------------------------

class _PulsingHint extends StatefulWidget {
  const _PulsingHint({required this.text});
  final String text;
  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Text(
        widget.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pokébola dibujada con CustomPainter
// ---------------------------------------------------------------------------

class _Pokeball extends StatelessWidget {
  const _Pokeball({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PokeballPainter()),
    );
  }
}

class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center.translate(0, 8), radius * 0.95, shadowPaint);

    final redPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(rect);
    canvas.drawArc(rect, pi, pi, true, redPaint);

    final whitePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
      ).createShader(rect);
    canvas.drawArc(rect, 0, pi, true, whitePaint);

    final bandPaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = radius * 0.14;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      bandPaint,
    );

    final outline = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = radius * 0.07
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - radius * 0.035, outline);

    canvas.drawCircle(center, radius * 0.24, Paint()..color = const Color(0xFF111827));
    canvas.drawCircle(center, radius * 0.18, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.10, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawCircle(
      Offset(center.dx - radius * 0.03, center.dy - radius * 0.03),
      radius * 0.05,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      Offset(center.dx - radius * 0.38, center.dy - radius * 0.45),
      radius * 0.18,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _PokeballPainter old) => false;
}

// ---------------------------------------------------------------------------
// Carta del monstruo (estilo TCG Pocket)
// ---------------------------------------------------------------------------

class _MonsterCard extends StatelessWidget {
  const _MonsterCard({
    required this.monster,
    required this.rarityColor,
    required this.shineValue,
    required this.isRare,
  });

  final Monster monster;
  final Color rarityColor;
  final double shineValue;
  final bool isRare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor,
            rarityColor.withOpacity(0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.7),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Marco interno blanco
              Container(color: Colors.white),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            monster.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: rarityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tier ${monster.level}',
                            style: TextStyle(
                              color: rarityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            rarityColor.withOpacity(0.18),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: rarityColor.withOpacity(0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          monster.imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Text(
                      monster.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        monster.rarity.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Brillo holográfico (banda diagonal que recorre la carta)
              if (isRare)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.6,
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) {
                          final t = shineValue;
                          return LinearGradient(
                            begin: Alignment(-1.5 + t * 3, -1.0),
                            end: Alignment(-0.5 + t * 3, 1.0),
                            colors: const [
                              Colors.transparent,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: const [0.35, 0.5, 0.65],
                          ).createShader(bounds);
                        },
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
