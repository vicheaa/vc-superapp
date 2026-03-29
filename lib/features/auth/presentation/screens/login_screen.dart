import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    final email = _emailController.text;
    final password = _passwordController.text;
    ref.read(authProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for errors from authProvider
    ref.listen<AsyncValue<AuthState>>(
      authProvider,
      (_, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${next.error}')),
          );
        }
      },
    );

    const primaryBlue = Color(0xFF0D52D6);
    const bgColor = Color(0xFFF9F9FB);
    const textColor = Color(0xFF2D3142);
    const subtitleColor = Color(0xFF5A5E73);
    const inputFillColor = Color(0xFFF1F3F5);

    return Scaffold(
      backgroundColor: bgColor,
      // appBar: AppBar(
      //   backgroundColor: bgColor,
      //   elevation: 0,
      //   title: const Text(
      //     'VC Supper App',
      //     style: TextStyle(
      //       color: textColor,
      //       fontWeight: FontWeight.w700,
      //       fontSize: 20,
      //       letterSpacing: -0.5,
      //     ),
      //   ),
      //   centerTitle: true,
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Heading
              const Text(
                'Welcome back.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subheading
              const Text(
                'Sign In to continue your curated journey.',
                style: TextStyle(
                  fontSize: 15,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 48),

              // Email Field Label
              const Text(
                'EMAIL ADDRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: const TextStyle(fontWeight: FontWeight.w500, color: textColor),
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: const TextStyle(color: Color(0xFF9094A6)),
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password Field Label
              const Text(
                'PASSWORD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                obscuringCharacter: '•',
                style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: subtitleColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign In Button
              ElevatedButton(
                onPressed: authState.isLoading ? null : _onLoginPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 40),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey.shade300),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONNECT WITH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: subtitleColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Social Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFF1F3F5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0.5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Google',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFF1F3F5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0.5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apple, size: 20, color: textColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Apple',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Create Account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
