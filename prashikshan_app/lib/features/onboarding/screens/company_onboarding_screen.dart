import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_palette.dart';
import '../models/company_onboarding_data.dart';
import '../services/user_service.dart';
import '../widgets/onboarding_components.dart';
import 'company_onboarding_steps.dart';

class CompanyOnboardingScreen extends StatefulWidget {
  const CompanyOnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends State<CompanyOnboardingScreen> {
  late final PageController _pageController;
  late final UserService _userService;
  CompanyOnboardingData _data = CompanyOnboardingData();
  int _currentStep = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _userService = UserService();
    
    // Auto-fill company email
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _data = _data.copyWith(companyEmail: user.email!);
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
      await _saveOnboardingData();
    }
  }

  Future<void> _saveOnboardingData() async {
    if (!_canProceed) return;

    setState(() => _isSaving = true);

    try {
      await _userService.saveCompanyOnboardingData(
        companyName: _data.companyName,
        companySize: _data.companySize,
        industryDomains: _data.industryDomains,
        hiringType: _data.hiringType,
        location: _data.location,
        websiteUrl: _data.websiteUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Company profile successfully set up! 🏢'),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) widget.onCompleted();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                CompanyOnboardingStep1(
                  data: _data,
                  onDataChanged: (val) => setState(() => _data = val),
                ),
                CompanyOnboardingStep2(
                  data: _data,
                  onDataChanged: (val) => setState(() => _data = val),
                ),
                CompanyOnboardingStep3(
                  data: _data,
                  onDataChanged: (val) => setState(() => _data = val),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: .1, end: 0),
            
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
                  border: Border(top: BorderSide(color: AppPalette.border)),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: GestureDetector(
                          onTap: _goToPreviousStep,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppPalette.border),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.arrow_back, color: AppPalette.textPrimary),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: OnboardingPrimaryButton(
                        label: _currentStep == 2 ? 'Launch Recruiter Portal' : 'Continue',
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
