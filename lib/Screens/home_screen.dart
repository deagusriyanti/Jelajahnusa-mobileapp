import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jelajah_nusa/screens/add_post_screen.dart';
import 'package:jelajah_nusa/screens/detail_screen.dart';
import 'package:jelajah_nusa/screens/edit_screen.dart';
import 'package:jelajah_nusa/screens/sign_in_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} secs ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else if (diff.inHours < 48) {
      return '1 day ago';
    } else {
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  Future<void> toggleLike(String postId, List likedBy) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (likedBy.contains(uid)) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likes': FieldValue.increment(-1),
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likes': FieldValue.increment(1),
      });
    }
  }

  ImageProvider? getProfileImage(Map<String, dynamic> data) {
    if (data['userPhotoBase64'] != null &&
        data['userPhotoBase64'].toString().isNotEmpty) {
      return MemoryImage(base64Decode(data['userPhotoBase64']));
    }

    if (data['userPhotoUrl'] != null &&
        data['userPhotoUrl'].toString().isNotEmpty) {
      return NetworkImage(data['userPhotoUrl']);
    }

    return null;
  }

  DateTime getCreatedAt(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF1E2A2F),
                          Theme.of(context).scaffoldBackgroundColor,
                        ]
                      : [const Color(0xFFBFEAEA), const Color(0xFFEAF1F2)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "JelajahNusa",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005B7F),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPostScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF005B7F)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF005B7F)),
                    ),
                  ),
                ],
              ),
            ),

            /// POST LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Belum ada postingan",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final data =
                            posts[index].data() as Map<String, dynamic>;

                        final String postId = posts[index].id;

                        final String fullName =
                            data['fullName'] ?? 'Unknown User';

                        final String title = data['title'] ?? '';

                        final String imageBase64 = data['image'] ?? '';

                        final String description = data['description'] ?? '';

                        final DateTime createdAt = getCreatedAt(data);

                        final double latitude = (data['latitude'] ?? 0.0)
                            .toDouble();

                        final double longitude = (data['longitude'] ?? 0.0)
                            .toDouble();

                        final String category = data['category'] ?? '';

                        final List likedBy = data['likedBy'] ?? [];

                        final int likes = data['likes'] ?? 0;

                        final String heroTag = 'image-$postId';

                        final ImageProvider? profileImage = getProfileImage(
                          data,
                        );

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
                                  latitude: latitude,
                                  longitude: longitude,
                                  category: category,
                                  heroTag: heroTag,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            color: Theme.of(context).scaffoldBackgroundColor,
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
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).cardColor,
                                        backgroundImage: profileImage,
                                        child: profileImage == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 22,
                                                color: Color(0xFF005B7F),
                                              )
                                            : null,
                                      ),

                                      const SizedBox(width: 10),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF005B7F),
                                            ),
                                          ),

                                          if (category.toString().isNotEmpty)
                                            Text(
                                              category,
                                              style: const TextStyle(
                                                color: Colors.teal,
                                                fontSize: 13,
                                              ),
                                            ),
                                        ],
                                      ),

                                      const Spacer(),

                                      Text(
                                        formatTime(createdAt),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),

                                      if (data['uid'] == currentUser?.uid)
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.grey,
                                          ),
                                          onSelected: (value) async {
                                            if (value == 'delete') {
                                              await FirebaseFirestore.instance
                                                  .collection('posts')
                                                  .doc(postId)
                                                  .delete();
                                            }

                                            if (value == 'edit') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditScreen(
                                                        postId: postId,
                                                        title: title,
                                                        description:
                                                            description,
                                                        imageBase64:
                                                            imageBase64,
                                                        latitude: latitude,
                                                        longitude: longitude,
                                                        category: category,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text("Edit"),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text("Hapus"),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                /// IMAGE
                                if (imageBase64.isNotEmpty)
                                  Hero(
                                    tag: heroTag,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(imageBase64),
                                        height: 250,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                /// DESCRIPTION & LIKE
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF007A8A),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              toggleLike(postId, likedBy);
                                            },
                                            child: Icon(
                                              likedBy.contains(currentUser?.uid)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.red,
                                              size: 34,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            likes.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
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
            ),
          ],
        ),
      ),
    );
  }
}
