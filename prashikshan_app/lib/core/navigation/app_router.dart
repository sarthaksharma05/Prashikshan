import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_palette.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/company_onboarding_screen.dart';
import '../../features/company/screens/company_root_screen.dart';
import '../../main_navigation.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Widget> _decideAuthenticatedScreen(User currentUser) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      debugPrint('🔍 [ROUTER] User doc exists: ${userDoc.exists}');

      // ⚠️ Race condition guard: Auth fires before Firestore write completes on signup.
      // Retry once after a short delay to give auth_service time to write the doc.
      if (!userDoc.exists) {
        debugPrint('⏳ [ROUTER] Doc missing — waiting for Firestore write...');
        await Future.delayed(const Duration(seconds: 2));
        userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        debugPrint('🔍 [ROUTER] After retry — exists: ${userDoc.exists}');
      }

      if (!userDoc.exists) {
        debugPrint('⚠️ [ROUTER] No doc after retry — defaulting to student onboarding');
        return _buildStudentOnboarding();
      }

      final Map<String, dynamic>? userData = userDoc.data();

      // ✅ DEBUG: Print full user document data
      debugPrint('👤 USER DATA: $userData');

      // Support both 'role' (new) and 'userType' (existing student docs)
      // ✅ FIXED: No hardcoded fallback to 'student' — null role shows error instead
      final String? rawRole = (userData?['role'] ?? userData?['userType'])
          ?.toString()
          .toLowerCase();

      // ✅ DEBUG: Print resolved role
      debugPrint('🏷️ ROLE: $rawRole');

      if (rawRole == null) {
        debugPrint('❌ [ROUTER] Role is null — cannot determine onboarding path');
        return _buildRoleErrorScreen();
      }

      final String role = rawRole;
      final bool isOnboarded = userData?['isOnboarded'] == true;

      debugPrint('✅ [ROUTER] Role: $role | isOnboarded: $isOnboarded');

      if (!isOnboarded) {
        if (role == 'company') {
          debugPrint('➡️ [ROUTER] Routing to: CompanyOnboardingScreen');
          return _buildCompanyOnboarding();
        }
        debugPrint('➡️ [ROUTER] Routing to: StudentOnboardingScreen');
        return _buildStudentOnboarding();
      }

      if (role == 'company') {
        debugPrint('➡️ [ROUTER] Routing to: CompanyRootScreen');
        return CompanyRootScreen(uid: currentUser.uid);
      }

      debugPrint('➡️ [ROUTER] Routing to: MainNavigation (Student)');
      return const MainNavigation();
    } catch (e) {
      debugPrint('❌ [ROUTER] Error: $e');
      return const AuthScreen();
    }
  }

  Widget _buildRoleErrorScreen() {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Account setup incomplete',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppPalette.pureWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your role could not be determined.\nPlease sign out and create a new account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: Text(
                'Sign Out',
                style: GoogleFonts.roboto(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStudentOnboarding() {
    return OnboardingScreen(
      onCompleted: () => setState(() {}),
    );
  }

  Widget _buildCompanyOnboarding() {
    return CompanyOnboardingScreen(
      onCompleted: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final User? user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return FutureBuilder<Widget>(
          future: _decideAuthenticatedScreen(user),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            return futureSnapshot.data ?? const AuthScreen();
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Prashikshan',
              style: GoogleFonts.roboto(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppPalette.pureWhite,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
