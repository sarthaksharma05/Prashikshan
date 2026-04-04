import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../screens/student_public_profile_screen.dart';

class StudentRankCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final int rank;

  const StudentRankCard({super.key, required this.student, required this.rank});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey.shade600;
  }

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final domains = List<String>.from(student['domains'] ?? []);
    return Card(
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank Badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _rankColor),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + University + chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? '',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppPalette.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student['university'] ?? '',
                        style: GoogleFonts.roboto(fontSize: 13, color: AppPalette.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _chip('CGPA: ${student['cgpa']}', Colors.blue.shade900),
                          const SizedBox(width: 6),
                          _chip('${student['projects_count']} Projects', Colors.purple.shade900),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: domains
                            .map((d) => _chip(d, Colors.teal.shade900))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // Social icons
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.code_rounded, color: AppPalette.textSecondary),
                      tooltip: 'GitHub',
                      onPressed: () => _launch(student['githubUrl']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_rounded, color: AppPalette.textSecondary),
                      tooltip: 'LinkedIn',
                      onPressed: () => _launch(student['linkedinUrl']),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: ${(student['score'] as num).toStringAsFixed(1)}',
                  style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textMuted),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                  builder: (_) => StudentPublicProfileScreen(
                        student: student,
                        rank: rank,
                        score: (student['score'] as num?)?.toDouble() ?? 0.0,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.pureWhite,
                    side: const BorderSide(color: AppPalette.border),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('View Profile', style: GoogleFonts.roboto(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.roboto(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
