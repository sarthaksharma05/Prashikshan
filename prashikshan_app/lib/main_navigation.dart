import 'package:flutter/material.dart';


import 'features/home/screens/home_screen.dart';
import 'features/resume/screens/resume_screen.dart';
import 'features/chat/screens/ai_mentor_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'widgets/bottom_navbar.dart';
import 'core/theme/app_palette.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // REMOVED const to ensure screens can react to index changes properly
  late final List<Widget> _screens = [
    const HomeScreen(),
    const ResumeScreen(),
    const AiMentorScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          debugPrint("Current Index: $index");
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
