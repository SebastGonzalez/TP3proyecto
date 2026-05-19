import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/gatcha_machine_repository.dart';
import 'package:prueba1/monsters/domain/gatcha_machine.dart';

final gatchaMachineRepositoryProvider = Provider<GatchaMachineRepository>(
  (ref) => GatchaMachineRepository(),
);

/// Lista de máquinas cargada desde Firestore (`gatcha_machines`).
/// Se vuelve a pedir al entrar en [GatchaScreen] (`ref.invalidate`).
final gatchaMachinesProvider = FutureProvider<List<GatchaMachine>>((ref) async {
  final repo = ref.read(gatchaMachineRepositoryProvider);
  return repo.getMachines();
});
