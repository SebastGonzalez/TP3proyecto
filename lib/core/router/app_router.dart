import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/screens/gatcha_screen.dart';
import 'package:prueba1/presentation/screens/home_screen.dart';
import 'package:prueba1/presentation/screens/login_screen.dart';
import 'package:prueba1/presentation/screens/signup_screen.dart';
import 'package:prueba1/presentation/screens/monster_details.dart';
import 'package:prueba1/presentation/screens/my_monster_screen.dart';
import 'package:prueba1/presentation/screens/pokedex_screen.dart';
import 'package:prueba1/presentation/screens/profile_screen.dart';
import 'package:prueba1/presentation/screens/settings_screen.dart';
import 'package:prueba1/presentation/screens/shop_screen.dart';
import 'package:prueba1/monsters/domain/sacrifice_challenge.dart';
import 'package:prueba1/presentation/screens/sacrifice_challenge_screen.dart';
import 'package:prueba1/presentation/screens/sacrifice_screen.dart';
import 'package:prueba1/presentation/screens/market_screen.dart';
import 'package:prueba1/presentation/screens/game_screen.dart';

final app_router = GoRouter(
  
  initialLocation: '/login',
  routes: [  
    GoRoute(path: '/login'  ,     builder: (context, state) =>  const LoginScreen(),),
    GoRoute(path: '/signup'  ,    builder: (context, state) =>  const SignupScreen(),),
    GoRoute(path: '/home'   ,     builder: (context, state) =>  HomeScreen(),),
    GoRoute(path: '/details',     builder: (context, state) =>  MonsterDetails(monster: state.extra as Monster),),
    GoRoute(path: '/settings',    builder: (context, state) =>  SettingsScreen(),),
    GoRoute(path: '/profile',     builder: (context, state) =>  ProfileScreen(),),
    GoRoute(path: '/pokedex',     builder: (context, state) =>  PokedexScreen(),),
    GoRoute(path: '/gatcha',      builder: (context, state) =>  GatchaScreen(),),
    GoRoute(path: '/mymonsters',  builder: (context, state) =>  MyMonsterScreen(),),
    GoRoute(path: '/shop',        builder: (context, state) =>  ShopScreen()),
    GoRoute(path: '/market',      builder: (context, state) => MarketScreen(),),
    GoRoute(path: '/game',        builder: (context, state) =>  GameScreen(),),
    GoRoute(path: '/sacrifice',   builder: (context, state) =>  const SacrificeScreen(),),
    GoRoute(
      path: '/sacrifice/challenge',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! SacrificeChallenge) {
          return const Scaffold(
            body: Center(child: Text('Desafío no válido')),
          );
        }
        return SacrificeChallengeScreen(challenge: extra);
      },
    ),
    ],
);