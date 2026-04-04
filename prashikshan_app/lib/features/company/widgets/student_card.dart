import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/models/user_model.dart';
import '../screens/student_profile_detail_screen.dart';

class StudentCard extends StatelessWidget {
  final UserModel student;

  const StudentCard({super.key, required this.student});

  double get talentScore {
    // Score = (projects * 2) + cgpa
    // We try to parse the cgpa as it's stored as a string in the dummy data
    final double cgpa = double.tryParse(student.cgpa ?? '0.0') ?? 0.0;
    return (student.projects.length * 2.0) + cgpa;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProfileDetailScreen(student: student),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileImage(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameAndScore(),
                        const SizedBox(height: 4),
                        Text(
                          student.university ?? 'Unknown University',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppPalette.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 16),
              _buildDomainChips(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildProfileImage() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.background,
        border: Border.all(color: AppPalette.border, width: 2),
        image: student.profilePhotoUrl != null
            ? DecorationImage(
                image: NetworkImage(student.profilePhotoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: student.profilePhotoUrl == null
          ? const Icon(Icons.person_outline_rounded, color: AppPalette.textSecondary, size: 28)
          : null,
    );
  }

  Widget _buildNameAndScore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            student.name,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppPalette.pureWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.pureWhite.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
              const SizedBox(width: 6),
              Text(
                talentScore.toStringAsFixed(1),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.pureWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(Icons.analytics_outlined, 'CGPA', student.cgpa ?? '0.0'),
        const SizedBox(width: 24),
        _buildStatItem(Icons.folder_copy_outlined, 'Projects', student.projects.length.toString()),
        const SizedBox(width: 24),
        _buildStatItem(Icons.work_outline_rounded, 'Level', student.level),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppPalette.textMuted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 10, color: AppPalette.textMuted, fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: AppPalette.pureWhite),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDomainChips() {
    return Wrap(
      spacing: 8,
      children: student.domains.take(2).map((domain) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.pureWhite.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            domain,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
