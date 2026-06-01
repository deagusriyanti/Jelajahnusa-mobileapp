import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jelajah_nusa/screens/detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String formatTime(DateTime dateTime) {
    return DateFormat('MMMM dd, yyyy').format(dateTime);
  }

  Future<void> deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  Future<void> editPost(String postId, String oldDescription) async {
    final TextEditingController controller = TextEditingController(
      text: oldDescription,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Postingan"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Edit deskripsi"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .update({'description': controller.text});

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF1F2),

      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  /// BACK
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),

                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF005B7F),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// HISTORY LIST
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('uid', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        "No history yet",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: posts.length,

                    itemBuilder: (context, index) {
                      final data = posts[index].data();

                      final postId = posts[index].id;

                      final imageBase64 = data['image'];

                      final description = data['description'];

                      final createdAt = (data['createdAt'] as Timestamp)
                          .toDate();

                      final fullName = data['fullName'] ?? 'Anonymous';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                postId: postId,
                                imageBase64: imageBase64,
                                description: description,
                                createdAt: createdAt,
                                fullName: fullName,
                                latitude: data['latitude'] ?? 0.0,
                                longitude: data['longitude'] ?? 0.0,
                                category: data['category'] ?? '',
                                heroTag: 'history-$index',
                              ),
                            ),
                          );
                        },

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),

                          color: const Color(0xFFEAF1F2),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              /// USER INFO
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),

                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      size: 32,
                                      color: Color(0xFF005B7F),
                                    ),

                                    const SizedBox(width: 10),

                                    Text(
                                      fullName,

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF005B7F),
                                      ),
                                    ),

                                    const Spacer(),

                                    Text(
                                      formatTime(createdAt),

                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),

                                    /// TITIK 3
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.grey,
                                      ),

                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          editPost(postId, description);
                                        }

                                        if (value == 'delete') {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  "Hapus Postingan",
                                                ),

                                                content: const Text(
                                                  "Yakin ingin menghapus postingan ini?",
                                                ),

                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },

                                                    child: const Text("Batal"),
                                                  ),

                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      await deletePost(postId);

                                                      if (mounted) {
                                                        Navigator.pop(context);
                                                      }
                                                    },

                                                    child: const Text("Hapus"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },

                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text("Edit"),
                                        ),

                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text("Hapus"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              /// IMAGE
                              Image.memory(
                                base64Decode(imageBase64),

                                height: 250,
                                width: double.infinity,

                                fit: BoxFit.cover,
                              ),

                              /// DESCRIPTION
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),

                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        description,

                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF007A8A),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Icon(
                                      (data['likedBy'] ?? []).contains(uid)
                                          ? Icons.favorite
                                          : Icons.favorite_border,

                                      color: Colors.red,
                                      size: 34,
                                    ),

                                    const SizedBox(width: 5),

                                    Text(
                                      "${data['likes'] ?? 0}",

                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
