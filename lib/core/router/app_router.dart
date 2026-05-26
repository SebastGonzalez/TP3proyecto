import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/features/auth/data/services/auth_service.dart';
import 'package:prueba1/features/auth/presentation/screens/login_screen.dart';
import 'package:prueba1/features/auth/presentation/screens/signup_screen.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/sacrifice/domain/models/sacrifice_challenge.dart';
import 'package:prueba1/features/gatcha/presentation/screens/gatcha_screen.dart';
import 'package:prueba1/presentation/screens/game_screen.dart';
import 'package:prueba1/features/home/presentation/screens/home_screen.dart';
import 'package:prueba1/features/trades/presentation/screens/market_screen.dart';
import 'package:prueba1/features/monsters/presentation/screens/monster_details.dart';
import 'package:prueba1/features/monsters/presentation/screens/my_monster_screen.dart';
import 'package:prueba1/features/monsters/presentation/screens/pokedex_screen.dart';
import 'package:prueba1/features/profile/presentation/screens/profile_screen.dart';
import 'package:prueba1/features/sacrifice/presentation/screens/sacrifice_challenge_screen.dart';
import 'package:prueba1/features/sacrifice/presentation/screens/sacrifice_screen.dart';
import 'package:prueba1/presentation/screens/settings_screen.dart';
import 'package:prueba1/features/shop/presentation/screens/shop_screen.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';

/// Notifica a GoRouter cuando cambia la sesión de Firebase Auth.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(AuthService.authStateChanges);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(userProvider);
      if (auth.isLoading) return null;

      final loggedIn = auth.value != null;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/signup';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Respeta barra de navegación / gestos en Android e iOS en todas las rutas.
          // top: false porque cada pantalla con AppBar ya evita el notch superior.
          return SafeArea(top: false, child: child);
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => HomeScreen(),
          ),
          GoRoute(
            path: '/details',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Monster) {
                return MonsterDetails(monster: extra);
              }
              throw ArgumentError(
                'Ruta /details requiere un Monster en state.extra',
              );
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => ProfileScreen(),
          ),
          GoRoute(
            path: '/pokedex',
            builder: (context, state) => PokedexScreen(),
          ),
          GoRoute(
            path: '/gatcha',
            builder: (context, state) => GatchaScreen(),
          ),
          GoRoute(
            path: '/mymonsters',
            builder: (context, state) => MyMonsterScreen(),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => ShopScreen(),
          ),
          GoRoute(
            path: '/market',
            builder: (context, state) => MarketScreen(),
          ),
          GoRoute(
            path: '/game',
            builder: (context, state) => GameScreen(),
          ),
          GoRoute(
            path: '/sacrifice',
            builder: (context, state) => const SacrificeScreen(),
          ),
          GoRoute(
            path: '/sacrifice/challenge',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! SacrificeChallenge) {
                return const Scaffold(
                  appBar: AppPageAppBar(title: 'Desafío'),
                  body: Center(child: Text('Desafío no válido')),
                );
              }
              return SacrificeChallengeScreen(challenge: extra);
            },
          ),
        ],
      ),
    ],
  );
});
