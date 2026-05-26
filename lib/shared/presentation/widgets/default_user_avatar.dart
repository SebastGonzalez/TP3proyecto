import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/domain/my_user.dart';
import 'package:prueba1/core/application/providers/my_user.provider.dart';

/// Avatar por defecto del jugador (drawer, perfil, etc.).
class DefaultUserAvatar extends ConsumerWidget {
  const DefaultUserAvatar({super.key, this.radius = 40});

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = resolveCharacterImagePath(
      ref.watch(myUserProvider).value?.characterImagePath,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.orange.shade50,
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: Transform.translate(
            offset: Offset(0, radius * 0.22),
            child: Transform.scale(
              scale: 1.65,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
