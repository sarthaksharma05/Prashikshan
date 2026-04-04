import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_palette.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('About this role'),
                  const SizedBox(height: 12),
                  _buildDescription(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Required Skills'),
                  const SizedBox(height: 16),
                  _buildSkills(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Location & Type'),
                  const SizedBox(height: 12),
                  _buildLocationInfo(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildEnrollButton(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      backgroundColor: AppPalette.background,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppPalette.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Opportunity Details',
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final company = job['company'] ?? 'Company';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'job_icon_${job['job_id']}',
          child: _CompanyLogo(company: company),
        ),
        const SizedBox(height: 24),
        Hero(
          tag: 'job_title_${job['job_id']}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              job['title'] ?? 'Position Title',
              style: GoogleFonts.roboto(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppPalette.pureWhite,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          company,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _brandColor(company),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppPalette.textMuted,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'Join ${job['company']} as a ${job['title']}. This role involves working within the ${job['domain']} ecosystem with a focus on delivering high-quality professional results. You will collaborate with cross-functional teams and contribute to the growth of the organization.',
      style: GoogleFonts.roboto(
        fontSize: 16,
        height: 1.6,
        color: AppPalette.textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSkills() {
    final skills = job['skills'] as List? ?? [];
    return Wrap(
      spacing: 10,
      runSpacing: 14,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppPalette.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.border),
          ),
          child: Text(
            skill.toString(),
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPalette.pureWhite,
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: AppPalette.textMuted, size: 22),
          const SizedBox(width: 14),
          Text(
            job['location'] ?? 'Remote',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppPalette.pureWhite,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.pureWhite.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'On-site',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppPalette.pureWhite,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildEnrollButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppPalette.background,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppPalette.pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enrollment submitted')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                'Enroll for this role',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _brandColor(String company) {
    if (company.contains('Google')) return const Color(0xFF4285F4);
    if (company.contains('Amazon')) return const Color(0xFFFF9900);
    if (company.contains('Flipkart')) return const Color(0xFF2874F0);
    if (company.contains('HCL')) return const Color(0xFF005696);
    if (company.contains('Samsung')) return const Color(0xFF1428A0);
    return AppPalette.textSecondary;
  }
}

class _CompanyLogo extends StatelessWidget {
  final String company;
  const _CompanyLogo({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppPalette.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Center(child: _buildLogo()),
    );
  }

  Widget _buildLogo() {
    if (company.contains('Google')) {
      return const Icon(Icons.search, color: Color(0xFF4285F4), size: 40);
    }
    if (company.contains('Amazon')) {
      return const Icon(Icons.shopping_cart, color: Color(0xFFFF9900), size: 36);
    }
    if (company.contains('Flipkart')) {
      return Text('f',
          style: GoogleFonts.roboto(
              color: const Color(0xFF2874F0),
              fontSize: 40,
              fontWeight: FontWeight.w900));
    }
    if (company.contains('HCL')) {
      return Text('HCL',
          style: GoogleFonts.roboto(
              color: const Color(0xFF005696),
              fontSize: 18,
              fontWeight: FontWeight.w900));
    }
    if (company.contains('Samsung')) {
      return const Icon(Icons.phone_android, color: Color(0xFF1428A0), size: 36);
    }
    return const Icon(Icons.business_rounded,
        color: AppPalette.pureWhite, size: 36);
  }
}
