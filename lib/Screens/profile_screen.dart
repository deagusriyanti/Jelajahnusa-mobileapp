import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jelajah_nusa/Screens/sign_in_screen.dart';
import 'package:jelajah_nusa/theme/theme_provider.dart';
import 'package:jelajah_nusa/Screens/history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF007C89),
                ),
              ),

              const SizedBox(height: 18),

              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  String username = user?.displayName ?? 'User';
                  String email = user?.email ?? '';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;

                    username = data['username'] ?? user?.displayName ?? 'User';

                    email = data['email'] ?? user?.email ?? '';
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFFEAF5F6),
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  size: 42,
                                  color: Colors.grey,
                                )
                              : null,
                        ),

                        const SizedBox(height: 14),

                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF007C89),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              _profileMenu(
                context: context,
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () {},
              ),

              const SizedBox(height: 14),

              _profileMenu(
                context: context,
                icon: Icons.history,
                title: 'Post History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _profileMenu(
                context: context,
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                onTap: () {
                  _showThemeBottomSheet(context);
                },
              ),

              const SizedBox(height: 14),

              _profileMenu(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Tema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Light Mode'),
                onTap: () {
                  context.read<ThemeProvider>().setTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                onTap: () {
                  context.read<ThemeProvider>().setTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('System Default'),
                onTap: () {
                  context.read<ThemeProvider>().setTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileMenu({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
