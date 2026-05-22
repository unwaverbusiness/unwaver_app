// ignore_for_file: unused_field

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:unwaver/screens/settings/profile/profile_screen.dart';

final Color _goldColor = const Color(0xFFBB8E13);

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedBottomIndex = 0;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
  final TextEditingController _searchController = TextEditingController();
  late final Stream<QuerySnapshot> _allPostsStream;
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _allPostsStream = FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .get();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavSelected(int index) {
    if (index == 2) {
      showDialog(
        context: context,
        builder: (ctx) => const PostCreationDialog(),
      );
      return;
    }

    setState(() {
      _selectedBottomIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "Unwaver Community",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 96,
      ),
      body: _buildBody(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedBottomIndex,
        onDestinationSelected: _onBottomNavSelected,
        height: 70,
        backgroundColor: Colors.black,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Reels',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedBottomIndex) {
      case 1:
        return _buildSearchSection(context);
      case 3:
        return _buildReelsSection(context);
      case 4:
        return _buildDashboardSection(context);
      default:
        return _buildHomeSection(context);
    }
  }

  Widget _buildHomeSection(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _goldColor));
        }

        final profileData = profileSnapshot.data?.data();
        final followedUsers = (profileData?['following'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        if (followedUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Home shows posts from people you follow. Follow others to see their community updates here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ),
          );
        }

        final feedQuery = FirebaseFirestore.instance
            .collection('community_posts')
            .where('authorId', whereIn: followedUsers.length > 10 ? followedUsers.sublist(0, 10) : followedUsers)
            .orderBy('timestamp', descending: true);

        return StreamBuilder<QuerySnapshot>(
          stream: feedQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _goldColor));
            }

            final posts = snapshot.data?.docs.toList() ?? [];
            if (posts.isEmpty) {
              return Center(
                child: Text(
                  'No posts yet from people you follow.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  postDoc: posts[index],
                  currentUserId: _currentUserId,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search community posts...',
              prefixIcon: const Icon(Icons.search_outlined),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _allPostsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: _goldColor));
              }

              final query = _searchController.text.trim().toLowerCase();
              final posts = snapshot.data?.docs.where((doc) {
                    final content = (doc['content'] ?? '').toString().toLowerCase();
                    final authorName = (doc['authorName'] ?? '').toString().toLowerCase();
                    return query.isEmpty ||
                        content.contains(query) ||
                        authorName.contains(query);
                  }).toList() ??
                  [];

              if (posts.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty
                        ? 'Search community posts by keyword or author.'
                        : 'No results for "$query".',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return PostCard(
                    postDoc: posts[index],
                    currentUserId: _currentUserId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReelsSection(BuildContext context) {
    final reelsStream = FirebaseFirestore.instance
        .collection('community_posts')
        .where('mediaType', isEqualTo: 'video')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: reelsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _goldColor));
        }

        final posts = snapshot.data?.docs.toList() ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No reels available yet. Add a video to share it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostCard(
              postDoc: posts[index],
              currentUserId: _currentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _goldColor));
        }

        final profileData = profileSnapshot.data?.data() ?? {};
        final followingCount = (profileData['following'] as List<dynamic>?)?.length ?? 0;
        final followersCount = (profileData['followers'] as List<dynamic>?)?.length ?? 0;
        final bio = profileData['bio'] as String? ??
            'Share a little about yourself so the community can connect with you.';
        final profileImage = profileData['photoUrl'] as String? ?? user?.photoURL;
        final displayName = profileData['displayName'] as String? ?? user?.displayName ?? 'Unwaver User';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade300,
                    foregroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                    child: profileImage == null
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(bio, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen())),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDashboardMetric('Posts', profileData['postCount'] ?? 0),
                  _buildDashboardMetric('Following', followingCount),
                  _buildDashboardMetric('Followers', followersCount),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Your Past Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .where('authorId', isEqualTo: _currentUserId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _goldColor));
                  }

                  final posts = snapshot.data?.docs.toList() ?? [];
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'You have not posted yet. Tap Add to create your first community update.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  }

                  return Column(
                    children: posts.map((postDoc) {
                      return PostCard(
                        postDoc: postDoc,
                        currentUserId: _currentUserId,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardMetric(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

// ============================================================================
// OPTIMIZED POST CARD WIDGET
// ============================================================================
class PostCard extends StatelessWidget {
  final DocumentSnapshot postDoc;
  final String currentUserId;

  const PostCard({super.key, required this.postDoc, required this.currentUserId});

  void _toggleLike() {
    final List likes = postDoc['likes'] ?? [];
    final bool isLiked = likes.contains(currentUserId);

    if (isLiked) {
      postDoc.reference.update({
        'likes': FieldValue.arrayRemove([currentUserId])
      });
    } else {
      postDoc.reference.update({
        'likes': FieldValue.arrayUnion([currentUserId])
      });
    }
  }

  void _deletePost() {
    postDoc.reference.delete();
    // Future Action: Also delete associated media from Storage if mediaUrl exists
  }

  void _sharePost() {
    Share.share('Check out this post on Unwaver:\n\n${postDoc['content']}');
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final data = postDoc.data() as Map<String, dynamic>;
    final TextEditingController editController = TextEditingController(text: data['content'] ?? '');
    String selectedType = data['type'] ?? 'General';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: ['General', 'Success', 'Q&A']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedType = value;
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Update your post text',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await postDoc.reference.update({
        'content': editController.text.trim(),
        'type': selectedType,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This will permanently delete your community post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      _deletePost();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = postDoc.data() as Map<String, dynamic>;
    final List likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(currentUserId);
    final String? mediaUrl = data['mediaUrl'];
    final Map<String, dynamic>? sharedItem = data['sharedItem']; // For goals/habits

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _goldColor.withValues(alpha: 0.15),
                child: Text(
                  data['authorInitial'] ?? 'U',
                  style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['authorName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _goldColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['type'] ?? 'General',
                        style: TextStyle(color: _goldColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                    onPressed: () => _showEditDialog(context),
                    tooltip: 'Edit post',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'Delete post',
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),

          // Text Content
          Text(
            data['content'] ?? '',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Media Content (Images)
          if (mediaUrl != null && data['mediaType'] == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(mediaUrl, width: double.infinity, fit: BoxFit.cover),
            ),
            
          // Shared Item Embed (Goals, Habits, Tasks)
          if (sharedItem != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_circle, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sharedItem['type'].toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600, fontWeight: FontWeight.bold)),
                        Text(sharedItem['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Interactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // LIKE BUTTON
                  InkWell(
                    onTap: _toggleLike,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isLiked ? Colors.redAccent : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${likes.length}",
                            style: TextStyle(
                              color: isLiked ? Colors.redAccent : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // COMMENT BUTTON
                  InkWell(
                    onTap: () {
                      // Future Action: Navigate to Comments Screen
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            "${data['commentCount'] ?? 0}",
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // SHARE BUTTON
              IconButton(
                icon: Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade500),
                onPressed: _sharePost,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          )
        ],
      ),
    );
  }
}

// ============================================================================
// NEW POST CREATION DIALOG (WITH MEDIA & ACTIVITY ATTACHMENT)
// ============================================================================
class PostCreationDialog extends StatefulWidget {
  const PostCreationDialog({super.key});

  @override
  State<PostCreationDialog> createState() => _PostCreationDialogState();
}

class _PostCreationDialogState extends State<PostCreationDialog> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = 'General';
  bool _isLoading = false;
  
  File? _selectedMedia;
  String? _mediaType; // 'image' or 'video'
  Map<String, dynamic>? _attachedActivity;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia(bool isVideo) async {
    final XFile? pickedFile = isVideo 
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
        _mediaType = isVideo ? 'video' : 'image';
      });
    }
  }

  void _showActivityAttachmentSheet() {
    // This mocks pulling data from your Goals/Habits collections
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Attach to Post", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.blue),
              title: const Text("Goal: Run a Marathon"),
              onTap: () {
                setState(() => _attachedActivity = {'type': 'Goal', 'title': 'Run a Marathon', 'id': 'mock_id_1'});
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.loop, color: Colors.green),
              title: const Text("Habit: Read 10 Pages"),
              onTap: () {
                setState(() => _attachedActivity = {'type': 'Habit', 'title': 'Read 10 Pages', 'id': 'mock_id_2'});
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String? mediaUrl;

      // 1. Upload Media if exists
      if (_selectedMedia != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('community_media/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await storageRef.putFile(_selectedMedia!);
        mediaUrl = await uploadTask.ref.getDownloadURL();
      }

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('community_posts').add({
        'authorId': user?.uid ?? 'unknown',
        'authorName': user?.displayName ?? 'Nick', // Mocked based on your profile config
        'authorInitial': (user?.displayName ?? 'Nick')[0].toUpperCase(),
        'type': _selectedType,
        'content': _contentController.text.trim(),
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType,
        'sharedItem': _attachedActivity,
        'likes': [],
        'commentCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Create Post", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Topic Dropdown
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: ['General', 'Success', 'Q&A']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600))))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Share your progress or ask a question...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Previews
            if (_selectedMedia != null)
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: _mediaType == 'image' ? DecorationImage(image: FileImage(_selectedMedia!), fit: BoxFit.cover) : null,
                      color: Colors.black87
                    ),
                    child: _mediaType == 'video' ? const Icon(Icons.videocam, color: Colors.white) : null,
                  ),
                  Positioned(
                    top: -10, right: -10,
                    child: IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _selectedMedia = null)),
                  )
                ],
              ),
              
            if (_attachedActivity != null)
              Chip(
                label: Text("${_attachedActivity!['type']}: ${_attachedActivity!['title']}"),
                onDeleted: () => setState(() => _attachedActivity = null),
                backgroundColor: Colors.blueGrey.shade50,
              ),

            // Action Toolbar (Media & Attachments)
            Row(
              children: [
                IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => _pickMedia(false)),
                IconButton(icon: const Icon(Icons.videocam, color: Colors.redAccent), onPressed: () => _pickMedia(true)),
                IconButton(icon: const Icon(Icons.flag_circle, color: Colors.green), onPressed: _showActivityAttachmentSheet, tooltip: "Attach Goal/Habit"),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Post to Community", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}