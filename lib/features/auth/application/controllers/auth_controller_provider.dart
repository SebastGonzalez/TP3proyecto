import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/features/auth/data/services/auth_service.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';

final authControllerProvider = Provider<AuthController>(AuthController.new);

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<User?> login({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw 'Nombre de usuario y contraseña son requeridos';
    }

    final trimmedUsername = username.trim();
    final user = await AuthService.loginWithUsername(
      username: trimmedUsername,
      password: password,
    );

    if (user != null) {
      _ref.read(loggedInUsernameProvider.notifier).state = trimmedUsername;
    }

    return user;
  }

  Future<User?> register({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw 'Nombre de usuario y contraseña son requeridos';
    }

    if (password != confirmPassword) {
      throw 'Las contraseñas no coinciden';
    }

    if (username.length < 3) {
      throw 'El nombre de usuario debe tener al menos 3 caracteres';
    }

    final trimmedUsername = username.trim();
    final user = await AuthService.registerWithUsername(
      username: trimmedUsername,
      password: password,
    );

    if (user != null) {
      await _ref
          .read(userRepositoryProvider)
          .createUser(uid: user.uid, username: trimmedUsername);
      _ref.invalidate(myUserProvider);
      _ref.read(loggedInUsernameProvider.notifier).state = trimmedUsername;
    }

    return user;
  }

  Future<void> logout() async {
    _ref.read(loggedInUsernameProvider.notifier).state = null;
    await AuthService.logout();
  }
}
