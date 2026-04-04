import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final skills = List<String>.from(job['skills'] ?? []);
    final domain = job['domain']?.toString() ?? '';
    final avatarColor = domainColor(domain);

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppPalette.pureWhite),
        title: Text('Job Details',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppPalette.pureWhite)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: avatarColor,
                  child: Text(
                    (job['company']?.toString() ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['title']?.toString() ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.pureWhite)),
                      Text(job['company']?.toString() ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.blue.shade300,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Location + domain row
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(job['location']?.toString() ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppPalette.textSecondary)),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: avatarColor.withOpacity(0.4)),
                  ),
                  child: Text(domain,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Skills section
            if (skills.isNotEmpty) ...[
              Text('Required Skills',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textMuted,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppPalette.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppPalette.border),
                          ),
                          child: Text(s,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppPalette.textSecondary)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Job ID
            Text(
              'Job ID: ${job['job_id'] ?? job['doc_id'] ?? '-'}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppPalette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
