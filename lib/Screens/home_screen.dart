import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jelajah_nusa/screens/add_post_screen.dart';
import 'package:jelajah_nusa/screens/detail_screen.dart';
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
      MaterialPageRoute(
        builder: (context) => const SignInScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> toggleLike(
    String postId,
    List likedBy,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1F2),

      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFBFEAEA),
                    Color(0xFFEAF1F2),
                  ],
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "JelajahNusa",

                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005B7F),
                    ),
                  ),

                  Row(
                    children: [
                      /// ADD POST BUTTON
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddPostScreen(),
                            ),
                          );
                        },

                        child: Container(
                          padding: const EdgeInsets.all(10),

                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF005B7F),
                            ),

                            borderRadius:
                                BorderRadius.circular(12),
                          ),

                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF005B7F),
                          ),
                        ),
                      ),

          ],
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
                      .orderBy(
                        'createdAt',
                        descending: true,
                      )
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Belum ada postingan",
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: posts.length,

                      itemBuilder: (context, index) {
                        final data =
                            posts[index].data()
                                as Map<String, dynamic>;
                        final fullName =
                           data['fullName'] ?? 'Unknown User';
                        /// FIRESTORE DOC ID
                        final String postId =
                            posts[index].id;

                        final imageBase64 =
                            data['image'] ?? '';

                        final description =
                            data['description'] ?? '';

                        final createdAt =
                            DateTime.parse(
                          data['createdAt'],
                        );

                        final latitude =
                            data['latitude'] ?? 0.0;

                        final longitude =
                            data['longitude'] ?? 0.0;

                        final category =
                            data['category'] ?? '';

                        final likedBy =
                            data['likedBy'] ?? [];

                        final likes =
                            data['likes'] ?? 0;

                        final heroTag =
                            'image-$index';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailScreen(
                                  postId: postId,
                                  imageBase64:
                                      imageBase64,
                                  description:
                                      description,
                                  createdAt:
                                      createdAt,
                                  fullName:
                                      fullName,
                                  latitude:
                                      latitude,
                                  longitude:
                                      longitude,
                                  category:
                                      category,
                                  heroTag:
                                      heroTag,
                                ),
                              ),
                            );
                          },

                          child: Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 14,
                            ),

                            color:
                                const Color(0xFFEAF1F2),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                /// USER INFO
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),

                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .account_circle_outlined,
                                        size: 34,
                                        color: Color(
                                          0xFF005B7F,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 10,
                                      ),

                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [
                                          Text(
                                            fullName,

                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  16,
                                              color: Color(
                                                0xFF005B7F,
                                              ),
                                            ),
                                          ),

                                          if (category
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              category,

                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors
                                                        .teal,
                                                fontSize:
                                                    13,
                                              ),
                                            ),
                                        ],
                                      ),

                                      const Spacer(),

                                      Text(
                                        formatTime(
                                          createdAt,
                                        ),

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors
                                                  .grey,
                                          fontSize:
                                              13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// IMAGE
                                Hero(
                                  tag: heroTag,

                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                      8,
                                    ),

                                    child: Image.memory(
                                      base64Decode(
                                        imageBase64,
                                      ),

                                      height: 250,
                                      width:
                                          double.infinity,
                                      fit:
                                          BoxFit.cover,
                                    ),
                                  ),
                                ),

                                /// DESCRIPTION & LIKE
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),

                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Expanded(
                                        child: Text(
                                          description,

                                          maxLines: 3,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,

                                          style:
                                              const TextStyle(
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color: Color(
                                              0xFF007A8A,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 12,
                                      ),

                                      Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              toggleLike(
                                                postId,
                                                likedBy,
                                              );
                                            },

                                            child: Icon(
                                              likedBy.contains(
                                                      FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid)
                                                  ? Icons
                                                      .favorite
                                                  : Icons
                                                      .favorite_border,

                                              color:
                                                  Colors
                                                      .red,
                                              size: 34,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 4,
                                          ),

                                          Text(
                                            likes
                                                .toString(),

                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors
                                                      .grey,
                                              fontSize:
                                                  16,
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