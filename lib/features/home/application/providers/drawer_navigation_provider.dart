import 'package:flutter_riverpod/legacy.dart';

/// Si es true, al volver a [HomeScreen] se abre el drawer automáticamente.
final reopenDrawerOnHomeProvider = StateProvider<bool>((ref) => false);
