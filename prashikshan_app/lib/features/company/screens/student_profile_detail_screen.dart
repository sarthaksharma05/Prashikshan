import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/models/user_model.dart';

class StudentProfileDetailScreen extends StatelessWidget {
  final UserModel student;

  const StudentProfileDetailScreen({super.key, required this.student});

  Future<void> _launchUrl(String? urlString, BuildContext context) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  double get talentScore {
    final double cgpa = double.tryParse(student.cgpa ?? '0.0') ?? 0.0;
    return (student.projects.length * 2.0) + cgpa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreBanner(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Profile Insights'),
                  const SizedBox(height: 16),
                  _buildInsightsGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Project Portfolio'),
                  const SizedBox(height: 16),
                  _buildProjectsList(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Technical Domains'),
                  const SizedBox(height: 16),
                  _buildDomainsWrap(),
                  const SizedBox(height: 48),
                  _buildSocialButtons(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      backgroundColor: AppPalette.background,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppPalette.pureWhite),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: const BoxDecoration(color: AppPalette.surface)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLargeProfileImage(),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: GoogleFonts.roboto(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.pureWhite,
                    ),
                  ),
                  Text(
                    student.university ?? 'Unknown University',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppPalette.textSecondary,
                      fontWeight: FontWeight.w500,
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

  Widget _buildLargeProfileImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.background,
        border: Border.all(color: AppPalette.border, width: 4),
        image: student.profilePhotoUrl != null
            ? DecorationImage(
                image: NetworkImage(student.profilePhotoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: student.profilePhotoUrl == null
          ? const Icon(Icons.person_outline_rounded, color: AppPalette.textSecondary, size: 48)
          : null,
    );
  }

  Widget _buildScoreBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B22), Color(0xFF0D1117)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.pureWhite.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TALENT SCORE',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'High Performance Candidate',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          Text(
            talentScore.toStringAsFixed(1),
            style: GoogleFonts.roboto(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppPalette.pureWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppPalette.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInsightsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _buildInsightItem(Icons.analytics_rounded, 'CGPA', student.cgpa ?? '0.0', Colors.blue),
        _buildInsightItem(Icons.folder_special_rounded, 'Projects', student.projects.length.toString(), Colors.purple),
        _buildInsightItem(Icons.work_history_rounded, 'Level', student.level, Colors.green),
        _buildInsightItem(Icons.email_outlined, 'Email', student.email, Colors.orange),
      ],
    );
  }

  Widget _buildInsightItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(fontSize: 10, color: AppPalette.textMuted, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.pureWhite, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    if (student.projects.isEmpty) {
      return Text('No projects listed', style: GoogleFonts.roboto(color: AppPalette.textMuted));
    }
    return Column(
      children: student.projects.map((proj) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proj['title'] ?? 'Untitled Project',
                style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w800, color: AppPalette.pureWhite),
              ),
              const SizedBox(height: 4),
              Text(
                proj['description'] ?? 'No description',
                style: GoogleFonts.roboto(fontSize: 13, color: AppPalette.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDomainsWrap() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: student.domains.map((domain) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppPalette.pureWhite.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.pureWhite.withOpacity(0.1)),
          ),
          child: Text(
            domain,
            style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.pureWhite),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Row(
      children: [
        if (student.githubUrl != null && student.githubUrl!.isNotEmpty)
          Expanded(
            child: _buildSocialButton(
              'GitHub',
              Icons.code_rounded,
              AppPalette.pureWhite,
              Colors.black,
              () => _launchUrl(student.githubUrl, context),
            ),
          ),
        if (student.githubUrl != null && student.linkedinUrl != null) const SizedBox(width: 16),
        if (student.linkedinUrl != null && student.linkedinUrl!.isNotEmpty)
          Expanded(
            child: _buildSocialButton(
              'LinkedIn',
              Icons.link_rounded,
              const Color(0xFF0077B5),
              AppPalette.pureWhite,
              () => _launchUrl(student.linkedinUrl, context),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w800),
      ),
    );
  }
}
