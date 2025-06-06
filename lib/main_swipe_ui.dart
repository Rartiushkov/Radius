import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_account_screen.dart';
import 'ride_map_screen.dart';

class SwipeHome extends StatefulWidget {
  const SwipeHome({super.key});

  @override
  State<SwipeHome> createState() => _SwipeHomeState();
}

class _SwipeHomeState extends State<SwipeHome> {
  final PageController _pageController = PageController();

  final List<_SwipeScreenData> pages = [
    _SwipeScreenData(
      title: "Doctor nearby",
      description: "If you feel unwell, a doctor can come to you.",
      buttonText: "Call Doctor",
      color: Colors.redAccent,
      iconPath: 'assets/images/doctor_nearby.png',
      serviceType: "Doctor",
    ),
    _SwipeScreenData(
      title: "Road Assistance",
      description: "Your car broke down? We are nearby.",
      buttonText: "Call Assistance",
      color: Colors.blueAccent,
      iconPath: 'assets/images/car_help.png',
      serviceType: "Mechanic",
    ),
    _SwipeScreenData(
      title: "Lawyer Support",
      description: "Conflict, police, threat? A lawyer is on the way.",
      buttonText: "Call Lawyer",
      color: Colors.green,
      iconPath: 'assets/images/lawyer_help.png',
      serviceType: "Lawyer",
    ),
  ];

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const UserAccountScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -10) {
            _openProfile();
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return Container(
              color: page.color.withAlpha(25),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(page.iconPath, height: 120),
                    const SizedBox(height: 20),
                    Text(page.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    Text(page.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RideMapScreen(serviceType: page.serviceType)));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        backgroundColor: page.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(page.buttonText, style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    Icon(Icons.keyboard_arrow_up, size: 40, color: Colors.grey),
                    const Text("Swipe up to Profile", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.logout),
      ),
    );
  }
}

class _SwipeScreenData {
  final String title;
  final String description;
  final String buttonText;
  final Color color;
  final String iconPath;
  final String serviceType;

  _SwipeScreenData({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.color,
    required this.iconPath,
    required this.serviceType,
  });
}