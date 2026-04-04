import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';
import '../screens/student_public_profile_screen.dart';

/// Pastel chip background colors that cycle per domain
const List<Color> _chipColors = [
  Color(0xFF1A3A5C),
  Color(0xFF1A3C34),
  Color(0xFF2D1F4E),
  Color(0xFF3C2A12),
  Color(0xFF2A1A2E),
];

class StudentDetailCard extends StatelessWidget {
  const StudentDetailCard({
    super.key,
    required this.student,
    required this.rank,
  });

  final Map<String, dynamic> student;
  final int rank;

  Future<void> _launch(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _rankBadge() {
    Color color;
    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700);
        break;
      case 2:
        color = const Color(0xFFC0C0C0);
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        break;
      default:
        color = AppPalette.surfaceLight;
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.background, width: 1.5),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: rank <= 3 ? Colors.black : AppPalette.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final domains = List<String>.from(student['domains'] ?? []);
    final score = (student['score'] as num?)?.toDouble() ?? 0.0;
    final domainColor0 = domains.isNotEmpty
        ? domainColor(domains.first)
        : Colors.grey.shade700;
    final name = student['name']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.border),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ROW ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar + rank badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: domainColor0,
                      child: Text(
                        initials(name),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: _rankBadge(),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name / university / stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.pureWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        student['university']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.school, size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            'CGPA: ${student['cgpa'] ?? '-'}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppPalette.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.folder_copy, size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            '${student['projects_count'] ?? 0} Projects',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppPalette.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade700.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(0)} pts',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade200,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20, color: AppPalette.border),

            // ─── ROW A — Domains ───
            if (domains.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.category, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: domains.asMap().entries.map((e) {
                        final bg = _chipColors[e.key % _chipColors.length];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e.value,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // ─── ROW B — Info chips ───
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if ((student['role']?.toString() ?? '').isNotEmpty)
                  _infoChip(Icons.work_outline, student['role'].toString()),
                if ((student['level']?.toString() ?? '').isNotEmpty)
                  _infoChip(Icons.star_outline, student['level'].toString()),
                if ((student['lookingFor']?.toString() ?? '').isNotEmpty)
                  _infoChip(Icons.search, student['lookingFor'].toString()),
              ],
            ),
            const SizedBox(height: 8),

            // ─── ROW C — Contact ───
            Row(
              children: [
                const Icon(Icons.phone, size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    student['mobileNumber']?.toString() ?? '-',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppPalette.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.email, size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    student['email']?.toString() ?? '-',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppPalette.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const Divider(height: 16, color: AppPalette.border),

            // ─── ACTION ROW ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.code,
                          color: Colors.white70, size: 20),
                      tooltip: 'GitHub',
                      onPressed: () => _launch(student['githubUrl']),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.link,
                          color: Color(0xFF0A66C2), size: 20),
                      tooltip: 'LinkedIn',
                      onPressed: () => _launch(student['linkedinUrl']),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_search, size: 14),
                  label: Text('Full Profile',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.pureWhite,
                    side: const BorderSide(color: AppPalette.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentPublicProfileScreen(
                          student: student,
                          rank: rank,
                          score: score,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppPalette.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppPalette.textSecondary)),
        ],
      ),
    );
  }
}
