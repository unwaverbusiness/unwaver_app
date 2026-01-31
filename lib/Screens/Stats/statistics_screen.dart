import 'package:flutter/material.dart';
// USING RELATIVE IMPORT to avoid path errors. 
// Adjust the number of "../" based on your folder structure.
import '../../widgets/main_drawer.dart'; 

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean background
      appBar: AppBar(
        title: const Text(
          "Performance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      // PASS THE ROUTE NAME FOR DRAWER HIGHLIGHTING
      drawer: const MainDrawer(currentRoute: '/statistics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: MAIN SCORECARD ---
            _buildMainScoreCard(),
            
            const SizedBox(height: 30),

            // --- SECTION 2: WEEKLY CONSISTENCY ---
            const Text(
              "Weekly Consistency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildWeeklyChart(),

            const SizedBox(height: 30),

            // --- SECTION 3: GOAL BREAKDOWN ---
            const Text(
              "Goal Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildGoalProgress("Marathon Training", 0.75),
            _buildGoalProgress("Business Revenue", 0.40),
            _buildGoalProgress("Reading (Books)", 0.20),
            _buildGoalProgress("Meditation", 0.90),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildMainScoreCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Discipline Score",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                "87%",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Top 10% of users",
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
          // Circular Progress Indicator used as a chart
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.87,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const Icon(Icons.trending_up, color: Colors.white, size: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Mock data for 7 days (0.0 to 1.0)
    final List<double> dailyProgress = [0.8, 0.6, 1.0, 0.9, 0.4, 0.8, 0.9];
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        return Column(
          children: [
            Container(
              width: 12,
              height: 100 * dailyProgress[index], // Height based on data
              decoration: BoxDecoration(
                color: dailyProgress[index] >= 0.8 ? Colors.black : Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGoalProgress(String title, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}