import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  bool _isLoading = false;
  bool _isUploading = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: _user?.displayName ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_user == null) return;
    
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;
      
      setState(() => _isUploading = true);
      
      final File file = File(image.path);
      final String path = 'profile_pictures/${_user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(path);
      
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _user.updatePhotoURL(downloadUrl);
      await _user.reload();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _user.updateDisplayName(_displayNameController.text.trim());
      await _user.reload();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getJoinDate() {
    if (_user == null) {
      return "Guest User (Not Logged In)";
    }
    if (_user.metadata.creationTime == null) {
      return "Member since unknown";
    }
    return "Member since ${DateFormat('MMMM yyyy').format(_user.metadata.creationTime!)}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- HEADER STACK ---
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Dark Background Header
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1a1a1a), Color(0xFF333333)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              
              // Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Settings/Share icon (placeholder for future use)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white70),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile sharing coming soon!")),
                    );
                  },
                ),
              ),

              // Overlapping Profile Picture
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.grey[900]! : Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                            child: _user?.photoURL == null
                                ? Icon(Icons.person, size: 55, color: Colors.grey.shade400)
                                : null,
                          ),
                        ),
                        if (_isUploading)
                          Container(
                            height: 110,
                            width: 110,
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        if (!_isUploading && _user != null)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37), // Unwaver Gold
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Space for the overlapping avatar
          const SizedBox(height: 50),

          // Join Date & Username
          Center(
            child: Text(
              _getJoinDate(),
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // --- ACHIEVEMENTS SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Achievements",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("View All", style: TextStyle(color: Color(0xFF1D8CA0))),
                )
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildAchievementCard(
                  icon: Icons.local_fire_department, 
                  color: Colors.orange, 
                  title: "7-Day Streak", 
                  subtitle: "Unstoppable!",
                  isDark: isDark,
                ),
                _buildAchievementCard(
                  icon: Icons.star_rounded, 
                  color: const Color(0xFFD4AF37), 
                  title: "Early Adopter", 
                  subtitle: "Joined Unwaver",
                  isDark: isDark,
                ),
                _buildAchievementCard(
                  icon: Icons.check_circle_rounded, 
                  color: Colors.teal, 
                  title: "Task Master", 
                  subtitle: "100 Tasks Done",
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- PROFILE DETAILS SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Profile Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Display Name Input
                  TextFormField(
                    controller: _displayNameController,
                    enabled: _user != null,
                    decoration: InputDecoration(
                      labelText: "Display Name",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty 
                        ? 'Please enter a display name' 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Read-only Email Input
                  TextFormField(
                    initialValue: _user?.email ?? 'No email associated',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Account Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      onPressed: (_isLoading || _user == null) ? null : _saveProfile,
                      child: _isLoading 
                          ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                          : Text(
                              _user == null ? "Login to Edit Profile" : "Save Changes", 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for rendering an achievement badge
  Widget _buildAchievementCard({
    required IconData icon, 
    required Color color, 
    required String title, 
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
