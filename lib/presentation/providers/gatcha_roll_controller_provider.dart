import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/owned_monster_repository.dart';
import 'package:prueba1/monsters/domain/gatcha_machine.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';
import 'package:prueba1/presentation/providers/owned_monsters_provider.dart';

final gatchaRollControllerProvider = Provider<GatchaRollController>(
  GatchaRollController.new,
);

class GatchaRollController {
  GatchaRollController(this._ref);

  final Ref _ref;

  String? validate({
    required GatchaMachine machine,
    required List<Monster> monsters,
    required int coins,
  }) {
    final ownerId =
        _ref.read(myUserProvider).value?.uid ??
        _ref.read(userProvider).value?.uid;
    if (ownerId == null) {
      return 'Iniciá sesión para tirar la gatcha';
    }

    if (coins < machine.cost) {
      return 'Necesitás ${machine.cost} monedas!';
    }

    final eligible = machine.filteredPool(monsters);
    if (eligible.isEmpty) {
      return 'No hay monstruos elegibles en esta máquina';
    }

    return null;
  }

  Future<GatchaRollResult> roll({
    required GatchaMachine machine,
    required List<Monster> monsters,
    required int coins,
    required Random rng,
  }) async {
    final message = validate(
      machine: machine,
      monsters: monsters,
      coins: coins,
    );
    if (message != null) return GatchaRollResult.failure(message);

    final won = machine.rollMany(monsters, rng);
    try {
      final captured = await _ref
          .read(ownedMonstersControllerProvider)
          .purchaseCaptures(cost: machine.cost, monsters: won);
      return GatchaRollResult.success([
        for (final instance in captured) instance.monster,
      ]);
    } on InsufficientCoinsException {
      return GatchaRollResult.failure('Necesitás ${machine.cost} monedas!');
    } catch (_) {
      return const GatchaRollResult.failure(
        'No se pudo completar la tirada. Intentá de nuevo.',
      );
    }
  }
}

class GatchaRollResult {
  const GatchaRollResult._({required this.created, this.message});

  const GatchaRollResult.success(List<Monster> created)
    : this._(created: created);

  const GatchaRollResult.failure(String message)
    : this._(created: const [], message: message);

  final List<Monster> created;
  final String? message;

  bool get isFailure => message != null;
}
