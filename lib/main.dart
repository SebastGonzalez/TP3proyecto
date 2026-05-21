import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/router/app_router.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ProviderScope(
      child: const _AppBootstrap(child: MainApp()),
    ),
  );
}

/// Carga sesión, nombre y perfil Firestore al iniciar la app.
class _AppBootstrap extends ConsumerWidget {
  const _AppBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authUsernameBootstrapProvider);
    ref.watch(myUserProvider);
    return child;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: app_router,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.orange,
      ),
    );
  }
}
