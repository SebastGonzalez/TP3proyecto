import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Dominio falso para convertir usernames en emails
  static const String _fakeDomain = '@Walkmons.com';

  /// Espera a que Firebase restaure la sesión guardada en el dispositivo.
  /// La sesión persiste al cerrar la app (mucho más de 10 minutos).
  static Future<void> waitForAuthReady() async {
    await _firebaseAuth.authStateChanges().first;
  }

  /// Convierte un username simple en un email falso
  static String _usernameToEmail(String username) {
    return '$username$_fakeDomain';
  }

  /// Login con username y password
  /// Convierte el username a email internamente
  static Future<User?> loginWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      final email = _usernameToEmail(username);

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(username.trim());

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error de login: $e';
    }
  }

  /// Registro con username y password
  /// Convierte el username a email internamente
  static Future<User?> registerWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      final email = _usernameToEmail(username);

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(username.trim());

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error de registro: $e';
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  /// Actualiza el nombre visible en Firebase Auth (displayName).
  static Future<void> updateDisplayName(String username) async {
    await _firebaseAuth.currentUser?.updateDisplayName(username.trim());
  }

  /// Obtiene el usuario actual
  static User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Extrae el nombre de usuario (displayName o email falso usuario@myapp.com).
  static String? usernameFromUser(User? user) {
    if (user == null) return null;

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user.email;
    if (email == null || !email.endsWith(_fakeDomain)) return null;
    return email.substring(0, email.length - _fakeDomain.length);
  }

  /// Stream del estado de autenticación
  static Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  /// Manejo de errores de Firebase Auth
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado. Por favor regístrate.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este usuario ya existe.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
