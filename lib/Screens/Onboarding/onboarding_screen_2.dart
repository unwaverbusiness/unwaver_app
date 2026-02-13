import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      // Navigate to your main app here
      print("Onboarding Finished");
      // Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea prevents UI from going under the notch/status bar
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. TOP BAR (SKIP) ---
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: TextButton(
                onPressed: () {
                   // Add Skip Logic Here
                   print("Skip Pressed");
                },
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // --- 2. MAIN CONTENT (EXPANDED PAGEVIEW) ---
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // SCREEN 1: Intro
                  _OnboardingPage(
                    title: "Structure Your\nPurpose.",
                    subtitle: "Welcome to Unwaver. The AI-powered life system designed to align your habits, goals, and schedule.",
                    // Graphic: Simple Icon Box
                    graphic: Container(
                      height: 240,
                      width: 240,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.layers_outlined, size: 80, color: Colors.black87),
                    ),
                  ),

                  // SCREEN 2: Goals (The complex one)
                  _OnboardingPage(
                    title: "Visualize Your\nAmbition.",
                    subtitle: "Turn vague dreams into concrete metrics. Set targets, track streaks, and watch your progress bar fill up.",
                    graphic: const _GoalStackGraphic(),
                  ),

                  // SCREEN 3: Habits (Placeholder)
                  _OnboardingPage(
                    title: "Build Unbreakable\nHabits.",
                    subtitle: "Consistency is key. Track your daily routines and build streaks that last.",
                    graphic: const Icon(Icons.repeat, size: 100, color: Colors.grey),
                  ),

                   // SCREEN 4: Coach (Placeholder)
                  _OnboardingPage(
                    title: "Your AI\nPerformance Coach.",
                    subtitle: "Get personalized insights and adjustments based on your actual data.",
                    graphic: const Icon(Icons.psychology, size: 100, color: Colors.grey),
                  ),

                   // SCREEN 5: Start (Placeholder)
                  _OnboardingPage(
                    title: "Ready to\nUnwaver?",
                    subtitle: "Let's set up your first goal and get you moving.",
                    graphic: const Icon(Icons.rocket_launch, size: 100, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // --- 3. BOTTOM BAR (INDICATORS + BUTTON) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(_totalPages, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.black : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Next Button
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
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
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
}

// --- SUB-WIDGET: Standard Page Layout ---
// Separated to prevent code duplication and layout errors
class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget graphic;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.graphic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flexible graphic area
          Center(
            child: SizedBox(
              height: 300, 
              width: double.infinity,
              child: Center(child: graphic),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET: The Goal Stack Graphic (Screen 2) ---
// Isolated in its own widget to manage constraints safely
class _GoalStackGraphic extends StatelessWidget {
  const _GoalStackGraphic();

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder ensures we know exactly how wide we can be
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth > 300 ? 300 : constraints.maxWidth;
        
        return SizedBox(
          width: width,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bottom Card
              Positioned(
                top: 40,
                child: Opacity(
                  opacity: 0.5,
                  child: Transform.scale(
                    scale: 0.9,
                    child: _GoalCard(
                      width: width,
                      title: "Read 20 Pages",
                      subtitle: "Growth • 12 Day Streak",
                      progress: 0.3,
                      color: Colors.purple,
                      icon: Icons.book,
                    ),
                  ),
                ),
              ),
              // Top Card
              Positioned(
                top: 0,
                child: _GoalCard(
                  width: width,
                  title: "Save \$10k",
                  subtitle: "Finance • 45% Complete",
                  progress: 0.45,
                  color: Colors.green,
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- SUB-WIDGET: Single Goal Card UI ---
class _GoalCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;

  const _GoalCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Crucial for preventing overflows
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progress", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}