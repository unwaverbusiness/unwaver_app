import 'package:flutter/material.dart';
import 'package:unwaver/widgets/app_logo.dart'; // Assuming this exists based on your code

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // We will add the other 4 screens here in subsequent steps
  final int _totalPages = 5;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to Main App / Auth
      Navigator.pushReplacementNamed(context, '/home'); 
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea ensures we don't overlap with system status bars
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP NAV (Skip Button) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- MAIN CONTENT AREA ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // SCREEN 1: The Introduction
                  _buildOnboardingPage(
                    title: "Structure Your\nPurpose.",
                    subtitle: "Welcome to Unwaver. The AI-powered life system designed to align your habits, goals, and schedule into one seamless flow.",
                    iconAsset: Icons.layers_outlined, 
                  ),
                  
                  // Placeholders for future screens (2-5)
                  _buildPlaceholderPage("Screen 2: Goals"),
                  _buildPlaceholderPage("Screen 3: Habits"),
                  _buildPlaceholderPage("Screen 4: AI Coach"),
                  _buildPlaceholderPage("Screen 5: Get Started"),
                ],
              ),
            ),

            // --- BOTTOM NAVIGATION AREA ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPage == index ? 24 : 6, // Expanded active dot
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.black : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Next / Action Button
                  // Matching the style of your FloatingActionButton (Black circle)
                  InkWell(
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
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

  // --- WIDGET BUILDER FOR SCREEN 1 ---
  Widget _buildOnboardingPage({
    required String title,
    required String subtitle,
    required IconData iconAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Graphic Area
          // Using a Container with the same shadow style as your Dashboard
          Center(
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24), // Slightly larger radius for hero image
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                   BoxShadow(
                    color: Colors.black.withOpacity(0.05), // Matching your alpha: 0.05
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Icon(
                iconAsset,
                size: 100,
                color: Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 48),

          // Typography matching your "Stats" and "Goal Tiles"
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800, // Matching the bold stats
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 16),

          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600], // Matching your subtitle grey
            ),
          ),
        ],
      ),
    );
  }

  // Temporary helper for the remaining screens
  Widget _buildPlaceholderPage(String text) {
    return Center(child: Text(text));
  }
}