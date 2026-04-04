import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_palette.dart';
import '../models/onboarding_data.dart';
import '../services/user_service.dart';
import '../widgets/onboarding_components.dart';
import 'onboarding_steps.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late final UserService _userService;
  OnboardingData _data = OnboardingData();
  int _currentStep = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _userService = UserService();
    _prefillRoleFromFirestore();
  }

  /// ✅ Fetch the stored role from Firestore and lock it into _data.
  /// This ensures the student onboarding always saves the correct role
  /// even if the user somehow arrives here with stale local state.
  Future<void> _prefillRoleFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      // Support both 'role' (new) and 'userType' (legacy)
      final String storedRole =
          (data?['role'] ?? data?['userType'] ?? 'student')
              .toString()
              .toLowerCase();

      debugPrint('🔍 [ONBOARDING] Prefilled role from Firestore: $storedRole');

      if (mounted) {
        setState(() {
          _data = _data.copyWith(role: storedRole);
        });
      }
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING] Could not prefill role: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextStep() async {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Final step - save data to Firestore
      await _saveOnboardingData();
    }
  }

  /// Save onboarding data to Firestore
  Future<void> _saveOnboardingData() async {
    if (!_canProceed) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('💾 [ONBOARDING] Saving student data | role: ${_data.role} | name: ${_data.fullName}');

      await _userService.saveUserOnboardingData(
        name: _data.fullName,
        mobileNumber: _data.mobileNumber,
        university: _data.university,
        cgpa: _data.cgpa,
        role: _data.role, // ✅ Role sourced from Firestore (prefilled in initState)
        domains: _data.selectedDomains,
        level: _data.level,
        lookingFor: _data.lookingFor,
      );

      debugPrint('✅ [ONBOARDING] Student profile saved successfully');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully! 🎉'),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to home after brief delay for UX polish
        await Future<void>.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          widget.onCompleted();
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppPalette.border),
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveOnboardingData,
            ),
          ),
        );
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool get _canProceed {
    return switch (_currentStep) {
      0 => _data.isStep1Valid,
      1 => _data.isStep2Valid,
      2 => _data.isStep3Valid,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: <Widget>[
                OnboardingStep1(
                  data: _data,
                  onDataChanged: (OnboardingData value) {
                    setState(() {
                      _data = value;
                    });
                  },
                ),
                OnboardingStep2(
                  data: _data,
                  onDataChanged: (OnboardingData value) {
                    setState(() {
                      _data = value;
                    });
                  },
                ),
                OnboardingStep3(
                  data: _data,
                  onDataChanged: (OnboardingData value) {
                    setState(() {
                      _data = value;
                    });
                  },
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: .2, end: 0, duration: 500.ms),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: OnboardingProgressBar(
                  currentStep: _currentStep,
                  totalSteps: 3,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppPalette.border),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    if (_currentStep > 0)
                      Expanded(
                        child: GestureDetector(
                          onTap: _goToPreviousStep,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppPalette.border),
                              color: Colors.transparent,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppPalette.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: OnboardingPrimaryButton(
                        label:
                            _currentStep == 2 ? 'Complete Setup' : 'Continue',
                        isEnabled: _canProceed && !_isSaving,
                        isLoading: _isSaving,
                        onPressed: _goToNextStep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
