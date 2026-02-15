import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; 
// --- UPDATED IMPORT ---
import 'package:unwaver/screens/accounts/register_screen.dart'; 

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false; 

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Structure Your\nPurpose.",
      "subtitle": "Stop drifting through life. Unwaver helps you align your daily actions with your ultimate vision.",
      "image": "assets/Unwaver_App_Icon.png", 
      "lottie": null,
      "icon": null,
      "isDark": true, 
    },
    {
      "title": "Define Your\nNorth Star.",
      "subtitle": "Vague dreams get forgotten. Concrete goals get achieved. Break down your lifetime ambitions.",
      "image": null,
      "lottie": null, 
      "icon": Icons.flag_circle_outlined, 
      "isDark": false,
    },
    {
      "title": "Engineer Your\nHabits.",
      "subtitle": "Success isn't an act, it's a habit. Build unbreakable streaks and reprogram your behaviors.",
      "image": null,
      "lottie": null,
      "icon": Icons.cyclone, 
      "isDark": false,
    },
    {
      "title": "Data-Driven\nAccountability.",
      "subtitle": "Your personal AI Coach analyzes your performance 24/7. Get brutal truths and personalized insights.",
      "image": null,
      "lottie": null,
      "icon": Icons.psychology_alt, 
      "isDark": false,
    },
    {
      "title": "Ready to\nUnwaver?",
      "subtitle": "The system is ready. The path is clear. It is time to stop planning and start executing.",
      "image": null,
      "lottie": null,
      "icon": Icons.rocket_launch_rounded, 
      "isDark": false,
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0 && !_isLoading) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- UPDATED NAVIGATION LOGIC ---
  Future<void> _finishOnboarding() async {
    setState(() {
      _isLoading = true; 
    });

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        // Navigate to RegisterScreen instead of MainLayout
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage < _onboardingData.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: Text("Skip", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16)),
                        )
                      else 
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _isLoading ? const NeverScrollableScrollPhysics() : null,
                    itemCount: _onboardingData.length,
                    onPageChanged: (int page) => setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(data: _onboardingData[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? InkWell(
                              onTap: _previousPage,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                height: 50, width: 50,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                                child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                              ),
                            )
                          : const SizedBox(width: 50),
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _currentPage == index ? 24 : 6,
                            decoration: BoxDecoration(color: _currentPage == index ? Colors.black : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _nextPage, 
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 60, width: 60,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: _isLoading
                             ? const SizedBox() 
                             : Icon(_currentPage == _onboardingData.length - 1 ? Icons.check : Icons.arrow_forward, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.white, 
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: Lottie.asset('assets/animations/loading.json'), 
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Setting up your system...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOnboardingPage({required Map<String, dynamic> data}) {
    bool isDarkStyle = data['isDark'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 300, 
              width: 300,
              decoration: BoxDecoration(
                color: isDarkStyle ? Colors.black : Colors.grey[50], 
                borderRadius: BorderRadius.circular(30),
                border: isDarkStyle ? null : Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: _buildGraphicContent(data), 
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data['title'],
            style: const TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(
            data['subtitle'],
            style: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphicContent(Map<String, dynamic> data) {
    if (data['lottie'] != null) {
      return Lottie.asset(data['lottie'], fit: BoxFit.contain);
    }
    if (data['image'] != null) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Image.asset(data['image'], fit: BoxFit.contain),
      );
    }
    return Icon(data['icon'] ?? Icons.error, size: 100, color: Colors.black87);
  }
}