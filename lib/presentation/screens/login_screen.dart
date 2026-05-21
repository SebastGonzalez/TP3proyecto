import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/services/auth_service.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 // En login_screen.dart reemplaza tu función _login por esta:
void _login() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nombre de usuario y contraseña son requeridos'), backgroundColor: Colors.red),
    );
    return;
  }

  final username = _usernameController.text.trim();

  try {
    final user = await AuthService.loginWithUsername(
      username: username,
      password: _passwordController.text,
    );

    if (user != null && mounted) {
      setLoggedInUsername(ref, username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, $username!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    }
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorMessage ?? 'Error desconocido'), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/LogoJuego.png',
                  width: 200,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  decoration: _fieldDecoration.copyWith(
                    hintText: 'Nombre de usuario',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: true,
                  decoration: _fieldDecoration.copyWith(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta? '),
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/signup'),
                      child: const Text('Registrate aqui'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration get _fieldDecoration {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade400, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
