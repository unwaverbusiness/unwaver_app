import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Logout function using Firebase
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Because we use the AuthGate in main.dart, 
    // the app will automatically switch back to the Login screen.
  }

  @override
  Widget build(BuildContext context) {
    // Get current user details from Firebase
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
              ),
            ),
            const SizedBox(height: 20),

            // User Info
            Text(
              user?.displayName ?? 'Unwaver User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'No email found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),

            // Profile Options
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Account Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {},
            ),
            const Divider(),

            // Logout Button
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}