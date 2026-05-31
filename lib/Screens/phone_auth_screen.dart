import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jelajah_nusa/Screens/main_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  String _verificationId = '';

  String _formatPhone(String phone) {
    String number = phone.trim();

    if (number.startsWith('0')) {
      number = '+62${number.substring(1)}';
    } else if (!number.startsWith('+')) {
      number = '+62$number';
    }

    return number;
  }

  Future<bool> _isPhoneRegistered(String phone) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Masukkan nomor telepon');
      return;
    }

    setState(() => _isLoading = true);

    final phone = _formatPhone(_phoneController.text);

    try {
      final registered = await _isPhoneRegistered(phone);

      if (!registered) {
        _showMessage('Nomor telepon belum terdaftar');
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          _showMessage(_getErrorMessage(e.code));
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });

          _showMessage('Kode OTP telah dikirim');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showMessage('Gagal mengirim OTP');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showMessage('Masukkan kode OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_getErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Format nomor telepon tidak valid';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'invalid-verification-code':
        return 'Kode OTP salah';
      case 'session-expired':
        return 'Kode OTP sudah kedaluwarsa';
      default:
        return 'Login nomor telepon gagal';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF007C89),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF007C89), width: 1.4),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF007C89),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: Text(
                  _otpSent ? 'Verifikasi OTP' : 'Login Telepon',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF007C89),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              if (!_otpSent) ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('No Telepon'),
                ),

                const SizedBox(height: 12),

                Text(
                  'Masukkan nomor yang sudah didaftarkan saat Sign Up. Contoh: 0857xxxxxxx',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 36),

                _button(text: 'KIRIM OTP', onTap: _isLoading ? null : _sendOtp),
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Kode OTP'),
                ),

                const SizedBox(height: 36),

                _button(
                  text: 'VERIFIKASI',
                  onTap: _isLoading ? null : _verifyOtp,
                ),

                const SizedBox(height: 18),

                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _sendOtp,
                    child: const Text(
                      'Kirim ulang OTP',
                      style: TextStyle(
                        color: Color(0xFF007C89),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _button({required String text, required VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: onTap,
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
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
