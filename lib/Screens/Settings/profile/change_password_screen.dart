import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _savePassword() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would make an API call to your backend/Firebase here
      
      // Simulating a successful password change and returning 'true' to the previous screen
      Navigator.pop(context, true);
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
          ),
          validator: validator,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your new password must be at least 8 characters long.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _buildPasswordField(
                label: "Current Password",
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your current password';
                  return null;
                },
              ),

              _buildPasswordField(
                label: "New Password",
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a new password';
                  if (value.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),

              _buildPasswordField(
                label: "Confirm New Password",
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your new password';
                  if (value != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Update Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}