import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _photoBase64;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      _usernameController.text = data['username'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _photoBase64 = data['photoBase64'];
      _photoUrl = data['photoUrl'] ?? user.photoURL;

      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    final compressed = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: 50,
    );

    if (compressed == null) return;

    setState(() {
      _photoBase64 = base64Encode(compressed);
      _photoUrl = null;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.teal),
                  title: Text(
                    'Ambil Foto',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.teal),
                  title: Text(
                    'Pilih dari Galeri',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_usernameController.text.trim().isEmpty) {
      _showMessage('Username tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': _usernameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'photoBase64': _photoBase64,
            'photoUrl': _photoUrl,
          });

      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: user.uid)
          .get();

      for (final post in posts.docs) {
        await post.reference.update({
          'fullName': _usernameController.text.trim(),
        });
      }

      await user.updateDisplayName(_usernameController.text.trim());

      if (!mounted) return;

      _showMessage('Profil berhasil diperbarui');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Gagal memperbarui profil');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF007C89),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF007C89), width: 1.4),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  ImageProvider? _getProfileImage() {
    if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      return MemoryImage(base64Decode(_photoBase64!));
    }

    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }

    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileImage = _getProfileImage();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007C89)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF007C89),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).cardColor,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 52,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF007C89),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            TextFormField(
              controller: _usernameController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: _inputDecoration('Username'),
            ),

            const SizedBox(height: 25),

            TextFormField(
              enabled: false,
              initialValue: user?.email ?? '',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              decoration: _inputDecoration('Email'),
            ),

            const SizedBox(height: 25),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: _inputDecoration('No Telepon'),
            ),

            const SizedBox(height: 45),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007C89),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
