import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Autofill completion
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unwaver/screens/accounts/login_screen.dart';
import 'package:unwaver/screens/main_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final Color _brandTeal = const Color(0xFF1D8CA0);
  final Color _brandBlack = const Color(0xFF000000);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- AUTH LOGIC (Sign Up) ---
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nameController.text.trim());
        
        // Tells the OS to prompt the user to save these credentials to their keychain
        TextInput.finishAutofillContext(); 
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SKIP LOGIC (Guest Mode) ---
  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Guest login failed: ${e.message}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Social Placeholders
  void _handleSocialSignIn(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connecting to $provider..."), behavior: SnackBarBehavior.floating),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              // Wrap the inputs in an AutofillGroup to bind them together for the OS
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Text("Join Unwaver",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _brandBlack, letterSpacing: -1, height: 1.1),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text("Create an account to start structuring your purpose.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Added predictive text hints to each field
                    _buildTextField(
                      controller: _nameController, 
                      label: "Full Name", 
                      icon: Icons.person_outline,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController, 
                      label: "Email", 
                      icon: Icons.email_outlined, 
                      inputType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isObscured: !_isPasswordVisible,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isObscured: !_isPasswordVisible,
                      textInputAction: TextInputAction.done, // Changes keyboard button to 'Done'
                      onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible), // Optional: let them see it
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlack,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isLoading ? null : _handleSignUp,
                        child: _isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // --- SOCIAL SECTION ---
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[200])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Or continue with", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[200])),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(icon: Icons.g_mobiledata_rounded, color: Colors.red, onTap: () => _handleSocialSignIn("Google")),
                        const SizedBox(width: 20),
                        _buildSocialButton(icon: Icons.apple, color: Colors.black, onTap: () => _handleSocialSignIn("Apple")),
                        const SizedBox(width: 20),
                        _buildSocialButton(icon: Icons.facebook, color: Colors.blue.shade800, onTap: () => _handleSocialSignIn("Facebook")),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: TextStyle(color: Colors.grey[600])),
                        GestureDetector(
                          onTap: _navigateToLogin,
                          child: Text("Log In", style: TextStyle(color: _brandTeal, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    // --- SKIP BUTTON ---
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _isLoading ? null : _handleSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[500],
                      ),
                      child: const Text("Skip for now", style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        width: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onVisibilityToggle,
    Iterable<String>? autofillHints, // Added parameter
    TextInputAction? textInputAction, // Added parameter
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      keyboardType: inputType,
      textInputAction: textInputAction, // Controls 'Next' vs 'Done' on keyboard
      autofillHints: autofillHints, // Feeds predictive text engines
      enableSuggestions: !isPassword, // Turns off predictions for passwords
      autocorrect: !isPassword, // Turns off autocorrect for passwords
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onVisibilityToggle,
        ) : null,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      ),
    );
  }
}