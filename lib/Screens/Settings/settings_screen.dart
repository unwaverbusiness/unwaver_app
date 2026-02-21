import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart'; // Added for Biometrics
import 'package:unwaver/Screens/notifications/notifications_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- MOCK STATE VARIABLES ---
  bool _emailUpdates = false;
  bool _darkMode = false;
  
  // Biometric State
  bool _biometricLogin = false; // Start false to force authentication to turn it on
  final LocalAuthentication _localAuth = LocalAuthentication();

  // --- LOGIC ---
  Future<void> _handleBiometricToggle(bool enable) async {
    if (enable) {
      try {
        // 1. Check if the device hardware supports biometrics
        final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

        if (!canAuthenticate) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometrics are not supported or set up on this device."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 2. Trigger the OS-level Face ID / Fingerprint prompt
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric login for Unwaver',
          options: const AuthenticationOptions(
            biometricOnly: true, // Prevents falling back to device PIN
            stickyAuth: true,    // Keeps prompt alive if app goes briefly to background
          ),
        );

        // 3. If successful, update the UI switch
        if (didAuthenticate && mounted) {
          setState(() {
            _biometricLogin = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometric login enabled successfully."),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: Save this preference to SharedPreferences later
        }
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Disabling doesn't require authentication, just turn it off
      setState(() {
        _biometricLogin = false;
      });
      // TODO: Remove preference from SharedPreferences later
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- PROFILE HEADER ---
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // --- SECTION: ACCOUNT ---
          _buildSectionHeader("Account"),
          _buildSettingsGroup([
            _buildTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {
                // Navigate to Edit Profile
              },
            ),
            _buildTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {},
            ),
            // Updated to use the new Biometric logic
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: "Biometric Login",
              value: _biometricLogin,
              onChanged: _handleBiometricToggle,
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: PREFERENCES ---
          _buildSectionHeader("Preferences"),
          _buildSettingsGroup([
            _buildTile(
              icon: Icons.notifications_none,
              title: "Push Notifications",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: "Email Updates",
              value: _emailUpdates,
              onChanged: (val) => setState(() => _emailUpdates = val),
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: DATA & AI ---
          _buildSectionHeader("Data & Intelligence"),
          _buildSettingsGroup([
            _buildTile(
              icon: Icons.history,
              title: "Clear AI Chat History",
              onTap: _showClearDataDialog,
            ),
            _buildTile(
              icon: Icons.download_outlined,
              title: "Export My Data",
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // --- SECTION: SUPPORT ---
          _buildSectionHeader("Support"),
          _buildSettingsGroup([
            _buildTile(
              icon: Icons.help_outline,
              title: "Help Center",
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.info_outline,
              title: "About Unwaver",
              trailing: const Text("v1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 40),

          // --- LOGOUT BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // Add Logout Logic Here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 35, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "John Doe", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "john.doe@example.com",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          final isLast = index == children.length - 1;
          
          return Column(
            children: [
              widget,
              if (!isLast)
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: subtitle != null 
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) 
          : null,
      value: value,
      onChanged: onChanged,
      activeTrackColor: Colors.black, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Chat History?"),
        content: const Text("This will permanently delete your conversation history with the AI Coach. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("History cleared.")),
              );
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}