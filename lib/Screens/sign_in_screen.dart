import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jelajah_nusa/screens/home_screen.dart';
import 'package:jelajah_nusa/screens/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_getErrorMessage(e.code));
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
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
            'fullName': user.displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': Timestamp.now(),
          });
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
        return 'User tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      default:
        return 'Login gagal';
    }
  }

  InputDecoration _figmaInputDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF006C7A),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffixIcon,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF006C7A), width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 10),
      contentPadding: const EdgeInsets.only(top: 18, bottom: 6),
      isDense: true,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
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
                                color: Color(0xFF006C7A),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
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
                                    0xFF006C7A,
                                  ).withOpacity(0.35),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _figmaInputDecoration(label: 'Username'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _figmaInputDecoration(
                            label: 'Password',
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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

                        const SizedBox(height: 38),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006C7A),
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Sign In with :',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: signInWithGoogle,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/google_icon.png',
                                    width: 22,
                                    height: 22,
                                  ),
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
