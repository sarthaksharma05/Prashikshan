import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';

const List<Color> _chipColors = [
  Color(0xFF1A3A5C), Color(0xFF1A3C34), Color(0xFF2D1F4E),
  Color(0xFF3C2A12), Color(0xFF2A1A2E),
];

class StudentPublicProfileScreen extends StatelessWidget {
  const StudentPublicProfileScreen({
    super.key,
    required this.student,
    required this.rank,
    required this.score,
  });

  final Map<String, dynamic> student;
  final int rank;
  final double score;

  Future<void> _launch(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Copied!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final domains = List<String>.from(student['domains'] ?? []);
    final name = student['name']?.toString() ?? '';
    final avatarColor =
        domains.isNotEmpty ? domainColor(domains.first) : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppPalette.pureWhite),
        title: Text('Student Profile',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppPalette.pureWhite)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── SECTION 1: Hero ───
            _heroSection(context, name, avatarColor),
            const SizedBox(height: 20),

            // ─── SECTION 2: Academic Info ───
            _card('Academic Details', [
              _labelValue('CGPA', student['cgpa']?.toString() ?? '-'),
              _labelValue('Projects', '${student['projects_count'] ?? 0}'),
              _labelValue('Level', student['level']?.toString() ?? '-'),
              _labelValue('Role', student['role']?.toString() ?? '-'),
              _labelValue('Looking For', student['lookingFor']?.toString() ?? '-'),
            ]),
            const SizedBox(height: 16),

            // ─── SECTION 3: Domains ───
            _card('Domains', [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: domains.asMap().entries.map((e) {
                    final bg = _chipColors[e.key % _chipColors.length];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e.value,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ─── SECTION 4: Contact ───
            _card('Contact', [
              _contactRow(context, Icons.email, 'Email',
                  student['email']?.toString() ?? ''),
              _contactRow(context, Icons.phone, 'Phone',
                  student['mobileNumber']?.toString() ?? ''),
              _linkRow(Icons.code, 'GitHub', student['githubUrl']),
              _linkRow(Icons.link, 'LinkedIn', student['linkedinUrl']),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _heroSection(
      BuildContext context, String name, Color avatarColor) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        break;
      default:
        rankColor = AppPalette.surfaceLight;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: avatarColor,
            child: Text(initials(name),
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.pureWhite)),
          const SizedBox(height: 4),
          Text(student['university']?.toString() ?? '',
              style: GoogleFonts.inter(
                  fontSize: 15, color: AppPalette.textSecondary)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.blue.shade700.withOpacity(0.4)),
                ),
                child: Text(
                  '${score.toStringAsFixed(1)} pts',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade200),
                ),
              ),
              const SizedBox(width: 10),
              // Rank badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rankColor.withOpacity(0.5)),
                ),
                child: Text(
                  'Rank #$rank',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: rankColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textMuted,
                    letterSpacing: 1.3)),
          ),
          const Divider(height: 1, color: AppPalette.border),
          ...children,
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppPalette.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.pureWhite)),
        ],
      ),
    );
  }

  Widget _contactRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppPalette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppPalette.textMuted)),
                Text(value.isEmpty ? '-' : value,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppPalette.pureWhite)),
              ],
            ),
          ),
          if (value.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: AppPalette.textMuted),
              onPressed: () => _copy(context, value),
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _linkRow(IconData icon, String label, String? url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppPalette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppPalette.textMuted)),
                Text(
                  (url == null || url.isEmpty) ? 'Not provided' : url,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: (url == null || url.isEmpty)
                          ? AppPalette.textMuted
                          : Colors.blue.shade300),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  size: 16, color: AppPalette.textMuted),
              onPressed: () => _launch(url),
            ),
        ],
      ),
    );
  }
}
