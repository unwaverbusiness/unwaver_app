import 'package:flutter/material.dart';
import 'package:unwaver/screens/main_layout.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- EXPANDED DATA WITH MORE DETAIL ---
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Structure Your\nPurpose.",
      "subtitle": "Stop drifting through life. Unwaver helps you align your daily actions with your ultimate vision, creating a seamless flow between what you do and who you want to become.",
      "image": "assets/Unwaver_App_Icon.png", 
      "icon": null,
      "isDark": true, // Special flag for the Black Background style
    },
    {
      "title": "Define Your\nNorth Star.",
      "subtitle": "Vague dreams get forgotten. Concrete goals get achieved. Break down your lifetime ambitions into actionable milestones and track your progress with absolute precision.",
      "image": null,
      "icon": Icons.flag_circle_outlined, // More detailed icon
      "isDark": false,
    },
    {
      "title": "Engineer Your\nHabits.",
      "subtitle": "Success isn't an act, it's a habit. Build unbreakable streaks, analyze your consistency, and reprogram your behaviors for automatic success using our advanced tracking system.",
      "image": null,
      "icon": Icons.cyclone, // More abstract/cool icon for habits
      "isDark": false,
    },
    {
      "title": "Data-Driven\nAccountability.",
      "subtitle": "Your personal AI Coach analyzes your performance 24/7. Get brutal truths, personalized insights, and the motivation you need exactly when you need it. No excuses.",
      "image": null,
      "icon": Icons.psychology_alt,
      "isDark": false,
    },
    {
      "title": "Ready to\nUnwaver?",
      "subtitle": "The system is ready. The path is clear. It is time to stop planning and start executing. Your journey to a structured, purposeful life begins now.",
      "image": null,
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

  // --- NEW: BACK NAVIGATION ---
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP NAV (Skip Button) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Only show skip if not on the last page
                  if (_currentPage < _onboardingData.length - 1)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  // Placeholder to keep height consistent if Skip is hidden
                  if (_currentPage == _onboardingData.length - 1)
                    const SizedBox(height: 48), 
                ],
              ),
            ),

            // --- MAIN CONTENT AREA ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(
                    data: _onboardingData[index],
                  );
                },
              ),
            ),

            // --- BOTTOM NAVIGATION AREA ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // --- 1. BACK BUTTON (Hidden on first page) ---
                  _currentPage > 0
                      ? InkWell(
                          onTap: _previousPage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        )
                      : const SizedBox(width: 50), // Spacer to keep layout balanced

                  // --- 2. PAGE INDICATORS (Centered) ---
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.black : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // --- 3. NEXT BUTTON ---
                  InkWell(
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentPage == _onboardingData.length - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({required Map<String, dynamic> data}) {
    // Check if this specific slide wants a dark background for the image (The Logo slide)
    bool isDarkStyle = data['isDark'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- GRAPHIC AREA ---
          Center(
            child: Container(
              height: 300, // Slightly larger
              width: 300,
              decoration: BoxDecoration(
                // Dynamic Background: Black if isDark, otherwise Grey[50]
                color: isDarkStyle ? Colors.black : Colors.grey[50], 
                borderRadius: BorderRadius.circular(30),
                border: isDarkStyle 
                    ? null // No border if black
                    : Border.all(color: Colors.grey.shade100),
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // If it's the dark slide, maybe add a subtle gradient or texture?
                    // keeping it solid black for now as requested.
                    
                    if (data['image'] != null)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Image.asset(
                          data['image'],
                          fit: BoxFit.contain,
                          // If your logo is black-only, you might need color: Colors.white here
                          // But assuming your logo is colored or white:
                        ),
                      )
                    else
                      Icon(
                        data['icon'],
                        size: 100,
                        color: Colors.black87,
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 48),

          // --- TITLE ---
          Text(
            data['title'],
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 16),

          // --- DESCRIPTION ---
          Text(
            data['subtitle'],
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700], // Slightly darker for readability
            ),
          ),
        ],
      ),
    );
  }
}