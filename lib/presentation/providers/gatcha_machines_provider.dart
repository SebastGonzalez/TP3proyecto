import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/domain/gatcha_machine.dart';

/// Expone la lista de máquinas disponibles. Hoy devuelve la constante
/// `kGatchaMachines` cargada en código, pero al estar detrás de un Provider
/// se puede migrar después a un `FutureProvider` que las traiga de Firestore
/// (eventos por temporada, máquinas limitadas, etc.) sin tocar la pantalla.
final gatchaMachinesProvider = Provider<List<GatchaMachine>>((ref) {
  return kGatchaMachines;
});
