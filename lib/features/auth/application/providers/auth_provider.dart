import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prueba1/features/auth/data/services/auth_service.dart';

// Provider que expone el usuario actual
final userProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// Nombre ingresado al iniciar sesión o registrarse (fuente principal en la UI).
final loggedInUsernameProvider = StateProvider<String?>((ref) => null);

/// Nombre visible en home, perfil y menú.
final currentUsernameProvider = Provider<String>((ref) {
  final fromLogin = ref.watch(loggedInUsernameProvider);
  if (fromLogin != null && fromLogin.isNotEmpty) return fromLogin;

  final user = ref.watch(userProvider).value;
  return AuthService.usernameFromUser(user) ?? 'Entrenador';
});

void setLoggedInUsername(WidgetRef ref, String username) {
  ref.read(loggedInUsernameProvider.notifier).state = username.trim();
}

void clearLoggedInUsername(WidgetRef ref) {
  ref.read(loggedInUsernameProvider.notifier).state = null;
}

/// Restaura el nombre desde Firebase si ya hay sesión al abrir la app.
final authUsernameBootstrapProvider = Provider<void>((ref) {
  ref.listen(userProvider, (_, next) {
    next.whenData((user) {
      if (user == null) {
        ref.read(loggedInUsernameProvider.notifier).state = null;
        return;
      }
      final saved = ref.read(loggedInUsernameProvider);
      if (saved == null || saved.isEmpty) {
        final name = AuthService.usernameFromUser(user);
        if (name != null) {
          ref.read(loggedInUsernameProvider.notifier).state = name;
        }
      }
    });
  });
});

// Provider para manejar el login
final loginProvider = FutureProvider.family<User?, Map<String, String>>((ref, credentials) async {
  final username = credentials['username'] ?? '';
  final password = credentials['password'] ?? '';

  if (username.isEmpty || password.isEmpty) {
    throw 'Nombre de usuario y contraseña son requeridos';
  }

  return AuthService.loginWithUsername(
    username: username,
    password: password,
  );
});

// Provider para manejar el registro
final registerProvider = FutureProvider.family<User?, Map<String, String>>((ref, credentials) async {
  final username = credentials['username'] ?? '';
  final password = credentials['password'] ?? '';
  final confirmPassword = credentials['confirmPassword'] ?? '';

  if (username.isEmpty || password.isEmpty) {
    throw 'Nombre de usuario y contraseña son requeridos';
  }

  if (password != confirmPassword) {
    throw 'Las contraseñas no coinciden';
  }

  if (username.length < 3) {
    throw 'El nombre de usuario debe tener al menos 3 caracteres';
  }

  return AuthService.registerWithUsername(
    username: username,
    password: password,
  );
});

// Provider para manejar el logout
final logoutProvider = FutureProvider<void>((ref) async {
  await AuthService.logout();
});
