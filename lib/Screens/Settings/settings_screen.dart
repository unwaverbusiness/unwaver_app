import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart'; 
import 'package:unwaver/screens/settings/notifications/notifications_screen.dart'; 
import 'package:unwaver/screens/settings/profile/edit_profile_screen.dart'; 
import 'package:unwaver/screens/settings/profile/change_password_screen.dart'; 
import 'package:unwaver/screens/settings/theme/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE VARIABLES ---
  String _userName = "Nick";
  String _userEmail = "unwaver.business@gmail.com";
  
  bool _emailUpdates = false;
  
  bool _biometricLogin = false; 
  final LocalAuthentication _localAuth = LocalAuthentication();

  // --- LOGIC ---
  
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userName,
          currentEmail: _userEmail,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _userName = result['name'] ?? _userName;
        _userEmail = result['email'] ?? _userEmail;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _navigateToChangePassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password updated successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    if (enable) {
      try {
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

        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric login for Unwaver',
          options: const AuthenticationOptions(
            biometricOnly: true, 
            stickyAuth: true,    
          ),
        );

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
      setState(() {
        _biometricLogin = false;
      });
    }
  }

  // --- THEME PICKER LOGIC (New feature) ---
  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Theme Customization", 
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color
                        )
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 1. Dark Mode Toggle
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: appThemeMode,
                    builder: (context, currentMode, child) {
                      final isDark = currentMode == ThemeMode.dark;
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        subtitle: Text("Inverts the main colors of the app.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        value: isDark,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) {
                          updateThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      );
                    },
                  ),
                  
                  const Divider(height: 32),

                  // 2. Accent Color Grid Picker
                  Text('Accent Color', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<Color>(
                    valueListenable: appThemeColor,
                    builder: (context, currentColor, child) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: availableThemeColors.length,
                        itemBuilder: (context, index) {
                          final color = availableThemeColors[index];
                          final isSelected = currentColor.value == color.value;
                          
                          // Ensure the checkmark is visible against the selected color
                          final checkColor = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

                          return GestureDetector(
                            onTap: () => updateThemeColor(color),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected 
                                  ? Border.all(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, width: 3) 
                                  : Border.all(color: Colors.transparent, width: 0),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: isSelected ? Icon(Icons.check, color: checkColor, size: 18) : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on the global theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // App Bar respects the global theme defined in main.dart
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(cardColor, borderColor, textColor),
          const SizedBox(height: 24),

          _buildSectionHeader("Account"),
          _buildSettingsGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            children: [
              _buildTile(
                icon: Icons.lock_outline,
                title: "Change Password",
                textColor: textColor,
                onTap: _navigateToChangePassword, 
              ),
              _buildSwitchTile(
                icon: Icons.fingerprint,
                title: "Biometric Login",
                value: _biometricLogin,
                textColor: textColor,
                onChanged: _handleBiometricToggle,
              ),
            ]
          ),

          const SizedBox(height: 24),

          _buildSectionHeader("Preferences"),
          _buildSettingsGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            children: [
              _buildTile(
                icon: Icons.notifications_none,
                title: "Push Notifications",
                textColor: textColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              _buildTile(
                icon: Icons.palette_outlined,
                title: "Themes",
                textColor: textColor,
                trailing: ValueListenableBuilder<Color>(
                  valueListenable: appThemeColor,
                  builder: (context, color, child) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    );
                  },
                ),
                onTap: _showThemePicker,
              ),
              _buildSwitchTile(
                icon: Icons.email_outlined,
                title: "Email Updates",
                value: _emailUpdates,
                textColor: textColor,
                onChanged: (val) => setState(() => _emailUpdates = val),
              ),
            ]
          ),

          const SizedBox(height: 24),

          _buildSectionHeader("Data & Intelligence"),
          _buildSettingsGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            children: [
              _buildTile(
                icon: Icons.history,
                title: "Clear AI Chat History",
                textColor: textColor,
                onTap: _showClearDataDialog,
              ),
              _buildTile(
                icon: Icons.download_outlined,
                title: "Export My Data",
                textColor: textColor,
                onTap: () {},
              ),
            ]
          ),

          const SizedBox(height: 24),

          _buildSectionHeader("Support"),
          _buildSettingsGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            children: [
              _buildTile(
                icon: Icons.help_outline,
                title: "Help Center",
                textColor: textColor,
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                textColor: textColor,
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.info_outline,
                title: "About Unwaver",
                textColor: textColor,
                trailing: const Text("v1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {},
              ),
            ]
          ),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
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

  Widget _buildProfileHeader(Color cardColor, Color borderColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.withOpacity(0.2),
            child: const Icon(Icons.person, size: 35, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _userEmail, 
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textColor),
            onPressed: _navigateToEditProfile, 
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
          color: Colors.grey.shade500,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children, required Color cardColor, required Color borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
                Divider(height: 1, thickness: 1, color: borderColor, indent: 56),
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
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: textColor)),
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
    Color? textColor,
  }) {
    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: textColor)),
      subtitle: subtitle != null 
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) 
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary, 
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
            child: Text("Cancel", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
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