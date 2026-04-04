import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_palette.dart';
import '../models/company_onboarding_data.dart';
import '../widgets/onboarding_components.dart';

// ─────────────────────────────────────────────────────────────
// STEP 1 — Company Identity
// ─────────────────────────────────────────────────────────────
class CompanyOnboardingStep1 extends StatelessWidget {
  const CompanyOnboardingStep1({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  final CompanyOnboardingData data;
  final ValueChanged<CompanyOnboardingData> onDataChanged;

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
                    'Company Identity',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tell us about your organization',
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
                          label: 'Company Name',
                          icon: Icons.business_outlined,
                          initialValue: data.companyName,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(companyName: value));
                          },
                        ),
                        const SizedBox(height: 16),
                        OnboardingFloatingInput(
                          label: 'Business Email',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          initialValue: data.companyEmail,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(companyEmail: value));
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Company Size',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OnboardingSegmentedButton(
                          options: const <String>[
                            'Startup',
                            'Small',
                            'Medium',
                            'Large',
                          ],
                          selected: data.companySize,
                          onSelected: (String value) {
                            onDataChanged(data.copyWith(companySize: value));
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

// ─────────────────────────────────────────────────────────────
// STEP 2 — Industry Domains
// (Roles to Hire REMOVED — collected per job posting instead)
// ─────────────────────────────────────────────────────────────
class CompanyOnboardingStep2 extends StatelessWidget {
  const CompanyOnboardingStep2({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  final CompanyOnboardingData data;
  final ValueChanged<CompanyOnboardingData> onDataChanged;

  // ✅ Dataset-aligned domains — matches ML model, job_postings CSV & filtering system
  static const List<(String, IconData)> industryDomains = <(String, IconData)>[
    ('AI/ML', Icons.memory),
    ('Web Development', Icons.web),
    ('Android Development', Icons.phone_android),
    ('Data Engineering', Icons.storage),
    ('Cloud & DevOps', Icons.cloud),
    ('Cybersecurity', Icons.security),
    ('UI/UX Design', Icons.design_services),
    ('Backend Development', Icons.settings),
    ('Game Development', Icons.videogame_asset),
    ('Blockchain', Icons.currency_bitcoin),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Industry Focus',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Which domains does your company operate in?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add specific roles when you post a job',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppPalette.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Industry Category'),
                const SizedBox(height: 4),
                _buildSectionSubtitle('Select all that apply'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: industryDomains.map(((String, IconData) item) {
                    final bool isSelected = data.industryDomains.contains(item.$1);
                    return OnboardingSelectableChip(
                      label: item.$1,
                      isSelected: isSelected,
                      icon: item.$2,
                      onSelected: () {
                        final List<String> updated =
                            List<String>.from(data.industryDomains);
                        isSelected
                            ? updated.remove(item.$1)
                            : updated.add(item.$1);
                        onDataChanged(data.copyWith(industryDomains: updated));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppPalette.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppPalette.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 3 — Presence & Logistics
// ─────────────────────────────────────────────────────────────
class CompanyOnboardingStep3 extends StatelessWidget {
  const CompanyOnboardingStep3({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  final CompanyOnboardingData data;
  final ValueChanged<CompanyOnboardingData> onDataChanged;

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
                    'Presence & Logistics',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Where can candidates find you?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  OnboardingGlassCard(
                    child: Column(
                      children: <Widget>[
                        OnboardingFloatingInput(
                          label: 'Headquarters (City)',
                          icon: Icons.location_on_outlined,
                          initialValue: data.location,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(location: value));
                          },
                        ),
                        const SizedBox(height: 16),
                        OnboardingFloatingInput(
                          label: 'Website URL (Optional)',
                          icon: Icons.language_outlined,
                          initialValue: data.websiteUrl,
                          onChanged: (String value) {
                            onDataChanged(data.copyWith(websiteUrl: value));
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Hiring Type'),
                        const SizedBox(height: 12),
                        OnboardingSegmentedButton(
                          options: const <String>['Internship', 'Full-time', 'Both'],
                          selected: data.hiringType,
                          onSelected: (String val) =>
                              onDataChanged(data.copyWith(hiringType: val)),
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

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppPalette.textSecondary,
        ),
      ),
    );
  }
}
