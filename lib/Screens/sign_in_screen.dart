import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jelajah_nusa/Screens/main_screen.dart';
import 'package:jelajah_nusa/Screens/sign_up_screen.dart';
import 'package:jelajah_nusa/Screens/phone_auth_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_getErrorMessage(e.code));
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Masukkan email terlebih dahulu');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      _showMessage('Link reset password telah dikirim ke email Anda');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMessage('Email belum terdaftar');
      } else if (e.code == 'invalid-email') {
        _showMessage('Format email tidak valid');
      } else {
        _showMessage('Gagal mengirim email reset password');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'username': user.displayName ?? 'Google User',
            'email': user.email,
            'phone': '',
            'photoUrl': user.photoURL,
            'createdAt': Timestamp.now(),
          });
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showMessage('Google Sign-In gagal');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email belum terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'invalid-credential':
        return 'Email atau password salah';
      default:
        return 'Login gagal';
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF007C89),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF007C89),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      suffixIcon: suffixIcon,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF007C89), width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 10),
      contentPadding: const EdgeInsets.only(top: 20, bottom: 8),
      isDense: true,
    );
  }

  Widget _authButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7F2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14380B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/bali.jpeg',
                  width: double.infinity,
                  height: 255,
                  fit: BoxFit.cover,
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 230,
                    ),
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5F6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(26),
                        topRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF007C89),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 42),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Signup',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(
                                    0xFF007C89,
                                  ).withOpacity(0.35),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 34),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(label: 'E-mail Address'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration(
                            label: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 17,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: GestureDetector(
                            onTap: _resetPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                color: Color(0xFF007C89),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007C89),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _authButton(
                          onTap: _signInWithGoogle,
                          icon: Image.asset(
                            'assets/google.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                          text: 'Continue with Google',
                        ),

                        const SizedBox(height: 14),

                        _authButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PhoneAuthScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.phone_android,
                            size: 24,
                            color: Color(0xFF14380B),
                          ),
                          text: 'Continue with Phone',
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Need an account? ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF007C89),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
