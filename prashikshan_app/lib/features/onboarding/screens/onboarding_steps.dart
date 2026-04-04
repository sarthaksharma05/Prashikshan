import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_palette.dart';
import '../models/onboarding_data.dart';
import '../widgets/onboarding_components.dart';

class OnboardingStep1 extends StatelessWidget {
  const OnboardingStep1({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  final OnboardingData data;
  final ValueChanged<OnboardingData> onDataChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Tell us about yourself',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ll personalize your experience based on your profile',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  OnboardingGlassCard(
                    child: Column(
                      children: <Widget>[
                        OnboardingFloatingInput(
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          initialValue: data.fullName,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(fullName: value));
                          },
                        ),
                        const SizedBox(height: 16),
                        OnboardingFloatingInput(
                          label: 'Email',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          initialValue: data.email,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(email: value));
                          },
                        ),
                        // ✅ REMOVED: Role toggle no longer shown here.
                        // Role is captured at signup and stored in Firestore.
                        // Student vs Company routing is handled by AppRouter.
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingStep2 extends StatelessWidget {
  const OnboardingStep2({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  final OnboardingData data;
  final ValueChanged<OnboardingData> onDataChanged;

  static const List<(String, IconData)> domains = <(String, IconData)>[
    ('AI/ML', Icons.memory),
    ('Web Development', Icons.language),
    ('Android Development', Icons.phone_android),
    ('Data Engineering', Icons.storage),
    ('Cloud & DevOps', Icons.cloud_queue),
    ('Cybersecurity', Icons.security),
    ('UI/UX Design', Icons.palette_outlined),
    ('Backend Development', Icons.settings_ethernet),
    ('Game Development', Icons.videogame_asset_outlined),
    ('Blockchain', Icons.currency_bitcoin),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'What interests you?',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select one or more areas of interest',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  OnboardingGlassCard(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: domains.map(((String, IconData) item) {
                        final bool isSelected =
                            data.selectedDomains.contains(item.$1);
                        return OnboardingSelectableChip(
                          label: item.$1,
                          isSelected: isSelected,
                          icon: item.$2,
                          onSelected: () {
                            final List<String> updated =
                                List<String>.from(data.selectedDomains);
                            if (isSelected) {
                              updated.remove(item.$1);
                            } else {
                              updated.add(item.$1);
                            }
                            onDataChanged(
                              data.copyWith(selectedDomains: updated),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingStep3 extends StatelessWidget {
  const OnboardingStep3({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  final OnboardingData data;
  final ValueChanged<OnboardingData> onDataChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Academic Details',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your university, CGPA, and mobile number',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  OnboardingGlassCard(
                    child: Column(
                      children: <Widget>[
                        OnboardingFloatingInput(
                          label: 'University',
                          icon: Icons.school_outlined,
                          initialValue: data.university,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(university: value));
                          },
                        ),
                        const SizedBox(height: 16),
                        OnboardingFloatingInput(
                          label: 'CGPA',
                          icon: Icons.workspace_premium_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          initialValue: data.cgpa,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(cgpa: value));
                          },
                        ),
                        const SizedBox(height: 16),
                        OnboardingFloatingInput(
                          label: 'Mobile Number',
                          icon: Icons.phone_iphone_outlined,
                          keyboardType: TextInputType.phone,
                          initialValue: data.mobileNumber,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(mobileNumber: value));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
