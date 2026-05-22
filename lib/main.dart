import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prueba1/core/router/app_router.dart';
import 'package:prueba1/core/services/auth_service.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.waitForAuthReady();
  runApp(
    const ProviderScope(
      child: _AppBootstrap(child: MainApp()),
    ),
  );
}

/// Sesión y perfil del jugador. Catálogo y colección se cargan en cada pantalla.
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

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(userProvider);
    final router = ref.watch(goRouterProvider);

    if (auth.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: Colors.orange,
        ),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Walkmons',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.orange,
      ),
    );
  }
}
