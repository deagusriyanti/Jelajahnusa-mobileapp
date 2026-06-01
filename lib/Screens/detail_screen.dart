import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:jelajah_nusa/Screens/map_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'full_image_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.postId,
    required this.imageBase64,
    required this.description,
    required this.createdAt,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.heroTag,
  });

  final String postId;
  final String imageBase64;
  final String description;
  final DateTime createdAt;
  final String fullName;
  final double latitude;
  final double longitude;
  final String category;
  final String heroTag;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

enum CommentFilter { top, newest }

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  final TextEditingController _replyController = TextEditingController();

  String locationName = "Loading location...";
  CommentFilter selectedFilter = CommentFilter.newest;
  final Map<String, bool> expandedReplies = {};

  @override
  void initState() {
    super.initState();
    getLocationName();
  }

  /// GET LOCATION NAME
  Future<void> getLocationName() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        setState(() {
          locationName = "${place.subAdministrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() {
        locationName = "Unknown location";
      });
    }
  }

  /// OPEN GOOGLE MAPS
  Future<void> openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
      );
    }
  }

  /// ADD COMMENT
  Future<void> addComment() async {
  if (_commentController.text.trim().isEmpty) {
    return;
  }

  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments')
      .add({
    'userId': uid,
    'name': widget.fullName,
    'comment': _commentController.text.trim(),
    'createdAt': Timestamp.now(),
    'likes': 0,
    'likedBy': [],
  });

  _commentController.clear();
}
  /// ADD REPLY
  Future<void> addReply(String commentId, String reply) async {
    if (reply.trim().isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final username = userDoc.data()?['username'] ?? 'User';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
          'userId': uid,
          'name': username,
          'reply': reply,
          'createdAt': Timestamp.now(),
        });

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .update({'replyCount': FieldValue.increment(1)});
  }

  Future<void> deleteComment(String commentId) async {
  final commentRef = FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments')
      .doc(commentId);

  final replies =
      await commentRef.collection('replies').get();

  for (var doc in replies.docs) {
    await doc.reference.delete();
  }

  await commentRef.delete();
}

Future<void> deleteReply(
  String commentId,
  String replyId,
) async {
  await FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments')
      .doc(commentId)
      .collection('replies')
      .doc(replyId)
      .delete();

  await FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments')
      .doc(commentId)
      .update({
        'replyCount': FieldValue.increment(-1),
      });
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

  @override
  Widget build(BuildContext context) {
    final createdAtFormatted = DateFormat(
      'dd MMM yyyy',
    ).format(widget.createdAt);

    return DefaultTabController(
      length: 2,

      child: Scaffold(
        backgroundColor: Colors.grey[100],

        body: Stack(
          children: [
            /// IMAGE
            SizedBox(
              height: 360,
              width: double.infinity,

              child: Hero(
                tag: widget.heroTag,

                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullscreenImageScreen(
                          imageBase64: widget.imageBase64,
                        ),
                      ),
                    );
                  },

                  child: Image.memory(
                    base64Decode(widget.imageBase64),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            /// BACK BUTTON
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: CircleAvatar(
                  backgroundColor: Colors.white70,

                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
              ),
            ),

            /// CONTENT
            DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.62,
              maxChildSize: 0.95,

              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(24),

                  decoration: const BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),

                  child: SingleChildScrollView(
                    controller: scrollController,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        /// USER & FAVORITE
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    widget.fullName,

                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  /// LOCATION
                                 GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MapScreen(
                                            latitude: widget.latitude,
                                            longitude: widget.longitude,
                                            locationName: locationName,
                                          ),
                                        ),
                                      );
                                    },

                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 20,
                                        ),

                                        const SizedBox(width: 5),

                                        Expanded(
                                          child: Text(
                                            locationName,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  /// CATEGORY
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),

                                      borderRadius: BorderRadius.circular(20),
                                    ),

                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        const Icon(
                                          Icons.category,
                                          size: 18,
                                          color: Colors.teal,
                                        ),

                                        const SizedBox(width: 6),

                                        Text(
                                          widget.category,

                                          style: const TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.postId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox();
                                }

                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;

                                final likedBy = data['likedBy'] ?? [];

                                final likes = data['likes'] ?? 0;

                                final uid =
                                    FirebaseAuth.instance.currentUser!.uid;

                                final isLiked = likedBy.contains(uid);

                                return Column(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey[100],

                                      child: IconButton(
                                        onPressed: () {
                                          toggleLike(widget.postId, likedBy);
                                        },

                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,

                                          color: Colors.red,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      likes.toString(),

                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// TAB BAR
                        const TabBar(
                          labelColor: Colors.teal,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.teal,

                          tabs: [
                            Tab(text: "Description"),
                            Tab(text: "Comment"),
                          ],
                        ),

                        SizedBox(
                          height: 500,

                          child: TabBarView(
                            children: [
                              /// DESCRIPTION TAB
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    const SizedBox(height: 20),

                                    Text(
                                      widget.description,

                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.8,
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          color: Colors.teal,
                                        ),

                                        const SizedBox(width: 8),

                                        Text(createdAtFormatted),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              /// COMMENT TAB
                              Column(
                                children: [
                                  /// INPUT COMMENT
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.white,

                                      borderRadius: BorderRadius.circular(18),

                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),

                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _commentController,

                                            decoration: const InputDecoration(
                                              border: InputBorder.none,

                                              hintText: "Tulis komentar...",
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          onPressed: addComment,

                                          icon: const Icon(
                                            Icons.send,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      ChoiceChip(
                                        label: const Text("Top"),
                                        selected:
                                            selectedFilter == CommentFilter.top,
                                        onSelected: (_) {
                                          setState(() {
                                            selectedFilter = CommentFilter.top;
                                          });
                                        },
                                      ),

                                      const SizedBox(width: 10),

                                      ChoiceChip(
                                        label: const Text("Newest"),
                                        selected:
                                            selectedFilter ==
                                            CommentFilter.newest,
                                        onSelected: (_) {
                                          setState(() {
                                            selectedFilter =
                                                CommentFilter.newest;
                                          });
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  /// COMMENT LIST
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(widget.postId)
                                          .collection('comments')
                                          .orderBy(
                                            selectedFilter == CommentFilter.top
                                                ? 'likes'
                                                : 'createdAt',
                                            descending: true,
                                          )
                                          .snapshots(),

                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final comments = snapshot.data!.docs;

                                        if (comments.isEmpty) {
                                          return const Center(
                                            child: Text("Belum ada komentar"),
                                          );
                                        }

                                        return ListView.builder(
                                          itemCount: comments.length,

                                          itemBuilder: (context, index) {
                                            final comment = comments[index];

                                            final data =
                                                comment.data()
                                                    as Map<String, dynamic>;

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),

                                              padding: const EdgeInsets.all(16),

                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F7F8),

                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),

                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  /// USER
                                                 Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 14,
                                                      backgroundColor: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 16,
                                                      ),
                                                    ),

                                                    const SizedBox(width: 10),

                                                    Expanded(
                                                      child: Text(
                                                        data['name'] ?? "User",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.teal,
                                                        ),
                                                      ),
                                                    ),

                                                    if (data['userId'] ==
                                                        FirebaseAuth.instance.currentUser!.uid)

                                                      PopupMenuButton<String>(
                                                        icon: const Icon(
                                                          Icons.more_vert,
                                                          size: 18,
                                                        ),

                                                        onSelected: (value) async {
                                                          if (value == 'delete') {
                                                            final confirm = await showDialog<bool>(
                                                              context: context,
                                                              builder: (_) => AlertDialog(
                                                                title: const Text("Hapus Komentar"),
                                                                content: const Text(
                                                                  "Yakin ingin menghapus komentar ini?",
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(context, false),
                                                                    child: const Text("Batal"),
                                                                  ),

                                                                  ElevatedButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(context, true),
                                                                    child: const Text("Hapus"),
                                                                  ),
                                                                ],
                                                              ),
                                                            );

                                                            if (confirm == true) {
                                                              await deleteComment(comment.id);
                                                            }
                                                          }
                                                        },

                                                        itemBuilder: (context) => [
                                                          const PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.delete,
                                                                  color: Colors.red,
                                                                ),
                                                                SizedBox(width: 10),
                                                                Text("Hapus"),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),

                                                  const SizedBox(height: 10),

                                                  /// COMMENT
                                                  Text(data['comment'] ?? ''),
                                                  const SizedBox(height: 8),

                                                  Row(
                                                    children: [
                                                      /// LIKE
                                                      IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        icon: Icon(
                                                          (data['likedBy'] ??
                                                                      [])
                                                                  .contains(
                                                                    FirebaseAuth
                                                                        .instance
                                                                        .currentUser!
                                                                        .uid,
                                                                  )
                                                              ? Icons.favorite
                                                              : Icons
                                                                    .favorite_border,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                        onPressed: () async {
                                                          final uid =
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser!
                                                                  .uid;

                                                          final commentRef =
                                                              FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                    'posts',
                                                                  )
                                                                  .doc(
                                                                    widget
                                                                        .postId,
                                                                  )
                                                                  .collection(
                                                                    'comments',
                                                                  )
                                                                  .doc(
                                                                    comment.id,
                                                                  );

                                                          if ((data['likedBy'] ??
                                                                  [])
                                                              .contains(uid)) {
                                                            await commentRef.update({
                                                              'likedBy':
                                                                  FieldValue.arrayRemove(
                                                                    [uid],
                                                                  ),
                                                              'likes':
                                                                  FieldValue.increment(
                                                                    -1,
                                                                  ),
                                                            });
                                                          } else {
                                                            await commentRef.update({
                                                              'likedBy':
                                                                  FieldValue.arrayUnion(
                                                                    [uid],
                                                                  ),
                                                              'likes':
                                                                  FieldValue.increment(
                                                                    1,
                                                                  ),
                                                            });
                                                          }
                                                        },
                                                      ),

                                                      const SizedBox(width: 4),

                                                      Text(
                                                        "${data['likes'] ?? 0}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),

                                                      const SizedBox(width: 20),

                                                      /// REPLY
                                                      InkWell(
                                                        onTap: () {
                                                       showModalBottomSheet(
                                                        context: context,
                                                        isScrollControlled: true,
                                                        backgroundColor: Colors.transparent,
                                                        builder: (context) {
                                                          final replyController = TextEditingController();

                                                          return Container(
                                                            height: MediaQuery.of(context).size.height * 0.75,
                                                            padding: EdgeInsets.only(
                                                              left: 20,
                                                              right: 20,
                                                              top: 20,
                                                              bottom:
                                                                  MediaQuery.of(context).viewInsets.bottom + 20,
                                                            ),
                                                            decoration: const BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.vertical(
                                                                top: Radius.circular(30),
                                                              ),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                Container(
                                                                  width: 60,
                                                                  height: 6,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.grey.shade300,
                                                                    borderRadius: BorderRadius.circular(30),
                                                                  ),
                                                                ),

                                                                const SizedBox(height: 20),

                                                                const Text(
                                                                  "Reply Comment",
                                                                  style: TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),

                                                                const SizedBox(height: 15),

                                                                Container(
                                                                  width: double.infinity,
                                                                  padding: const EdgeInsets.all(14),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.grey.shade100,
                                                                    borderRadius: BorderRadius.circular(15),
                                                                  ),
                                                                  child: Text(
                                                                    data['comment'] ?? '',
                                                                    maxLines: 3,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: TextStyle(
                                                                      color: Colors.grey.shade700,
                                                                    ),
                                                                  ),
                                                                ),

                                                                const SizedBox(height: 20),

                                                                Expanded(
                                                                  child: TextField(
                                                                    controller: replyController,
                                                                    autofocus: true,
                                                                    expands: true,
                                                                    maxLines: null,
                                                                    minLines: null,
                                                                    textAlignVertical: TextAlignVertical.top,
                                                                    decoration: InputDecoration(
                                                                      hintText: "Write your reply...",
                                                                      filled: true,
                                                                      fillColor: Colors.grey.shade100,
                                                                      border: OutlineInputBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(20),
                                                                        borderSide: BorderSide.none,
                                                                      ),
                                                                      contentPadding:
                                                                          const EdgeInsets.all(20),
                                                                    ),
                                                                  ),
                                                                ),

                                                                const SizedBox(height: 20),

                                                                SizedBox(
                                                                  width: double.infinity,
                                                                  height: 55,
                                                                  child: ElevatedButton.icon(
                                                                    icon: const Icon(Icons.send),
                                                                    label: const Text(
                                                                      "Send Reply",
                                                                      style: TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.teal,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(18),
                                                                      ),
                                                                    ),
                                                                    onPressed: () async {
                                                                      await addReply(
                                                                        comment.id,
                                                                        replyController.text,
                                                                      );

                                                                      if (!mounted) return;

                                                                      setState(() {
                                                                        expandedReplies[comment.id] = true;
                                                                      });

                                                                      Navigator.pop(context);
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                        },
                                                        child: const Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .reply_outlined,
                                                              size: 18,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              "Reply",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  /// REPLY BUTTON
                                                  /// REPLIES
                                                  StreamBuilder<QuerySnapshot>(
                                                    stream: FirebaseFirestore
                                                        .instance
                                                        .collection('posts')
                                                        .doc(widget.postId)
                                                        .collection('comments')
                                                        .doc(comment.id)
                                                        .collection('replies')
                                                        .orderBy('createdAt')
                                                        .snapshots(),

                                                    builder: (context, replySnapshot) {
                                                      if (!replySnapshot
                                                          .hasData) {
                                                        return const SizedBox();
                                                      }

                                                      final replies =
                                                          replySnapshot
                                                              .data!
                                                              .docs;

                                                      final isExpanded =
                                                          expandedReplies[comment
                                                              .id] ??
                                                          false;

                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (replies
                                                              .isNotEmpty)
                                                            TextButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  expandedReplies[comment
                                                                          .id] =
                                                                      !isExpanded;
                                                                });
                                                              },

                                                              child: Text(
                                                                isExpanded
                                                                    ? "Sembunyikan balasan"
                                                                    : "${data['replyCount'] ?? replies.length} replies",
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .blue,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),

                                                          if (isExpanded)
                                                            ...replies.map((
                                                              replyDoc,
                                                            ) {
                                                              final replyData =
                                                                  replyDoc
                                                                          .data()
                                                                      as Map<
                                                                        String,
                                                                        dynamic
                                                                      >;

                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets.only(
                                                                      left: 40,
                                                                      top: 10,
                                                                    ),

                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      12,
                                                                    ),

                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        14,
                                                                      ),
                                                                ),

                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,

                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Text(
                                                                            replyData['name'] ?? 'User',
                                                                            style: const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.teal,
                                                                            ),
                                                                          ),
                                                                        ),

                                                                        if (replyData['userId'] ==
                                                                            FirebaseAuth.instance.currentUser!.uid)

                                                                          IconButton(
                                                                            icon: const Icon(
                                                                              Icons.delete_outline,
                                                                              color: Colors.red,
                                                                              size: 18,
                                                                            ),
                                                                            onPressed: () async {
                                                                              await deleteReply(
                                                                                comment.id,
                                                                                replyDoc.id,
                                                                              );
                                                                            },
                                                                          ),
                                                                      ],
                                                                    ),

                                                                    const SizedBox(
                                                                      height: 6,
                                                                    ),

                                                                    Text(
                                                                      replyData['reply'] ??
                                                                          '',
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
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
            ),
          ],
        ),
      ),
    );
  }
}
