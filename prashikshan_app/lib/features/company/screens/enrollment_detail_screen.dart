import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_palette.dart';

class EnrollmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> enrollment;
  final String enrollmentId;
  final String companyUid;

  const EnrollmentDetailScreen({
    super.key,
    required this.enrollment,
    required this.enrollmentId,
    required this.companyUid,
  });

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    return DateFormat('dd MMM yyyy').format(ts.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reviewed':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(enrollmentId)
          .update({'status': status});
      if (context.mounted) {
        String msg = status == 'reviewed' ? 'Marked as reviewed' : 'Applicant $status!';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context); // Go back after decision
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJob = enrollment['type'] == 'job';

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isJob ? 'Job Application' : 'Hackathon Registration',
              style: GoogleFonts.inter(fontSize: 16, color: AppPalette.textSecondary),
            ),
            Text(
              enrollment['item_title'] ?? 'Title',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppPalette.pureWhite),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApplicationInfoCard(),
            const SizedBox(height: 16),
            _buildStudentProfileCard(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Details', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.pureWhite)),
          const SizedBox(height: 16),
          _infoRow('Position/Event', enrollment['item_title'] ?? 'Unknown'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Domain:', style: GoogleFonts.roboto(color: AppPalette.textSecondary, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppPalette.surfaceLight, borderRadius: BorderRadius.circular(6)),
                child: Text(enrollment['item_domain'] ?? '', style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Applied On', _formatDate(enrollment['enrolled_at'] as Timestamp?)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Status:', style: GoogleFonts.roboto(color: AppPalette.textSecondary, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(enrollment['status'] ?? 'pending').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getStatusColor(enrollment['status'] ?? 'pending').withOpacity(0.5)),
                ),
                child: Text(
                  (enrollment['status'] ?? 'pending').toUpperCase(),
                  style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(enrollment['status'] ?? 'pending')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Applicant Profile', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.pureWhite)),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Text(
                  (enrollment['student_name'] ?? 'S')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(enrollment['student_name'] ?? 'Student Name', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: AppPalette.pureWhite)),
                    Text(enrollment['student_university'] ?? 'University', style: GoogleFonts.roboto(fontSize: 14, color: AppPalette.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _smallChip('CGPA: ${enrollment['student_cgpa'] ?? 'N/A'}'),
                        const SizedBox(width: 8),
                        _smallChip('Projects: ${enrollment['student_projects_count'] ?? 0}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Role', enrollment['student_role'] ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow('Level', enrollment['student_level'] ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow('Looking For', enrollment['student_lookingFor'] ?? 'N/A'),
          const SizedBox(height: 16),
          Text('Domains:', style: GoogleFonts.roboto(color: AppPalette.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (enrollment['student_domains'] as List<dynamic>? ?? []).map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppPalette.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppPalette.border)),
              child: Text(d.toString(), style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.pureWhite)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppPalette.border),
          const SizedBox(height: 8),
          _contactRow(Icons.email, enrollment['student_email'] ?? ''),
          const SizedBox(height: 8),
          _contactRow(Icons.phone, enrollment['student_phone'] ?? ''),
          const SizedBox(height: 16),
          Row(
            children: [
              if ((enrollment['student_githubUrl'] ?? '').isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.code, color: AppPalette.pureWhite),
                  tooltip: 'GitHub',
                  onPressed: () => _launchUrl(enrollment['student_githubUrl']),
                ),
              if ((enrollment['student_linkedinUrl'] ?? '').isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.work, color: AppPalette.pureWhite),
                  tooltip: 'LinkedIn',
                  onPressed: () => _launchUrl(enrollment['student_linkedinUrl']),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _smallChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppPalette.surfaceLight, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: GoogleFonts.roboto(fontSize: 10, color: AppPalette.textPrimary)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text('$label:', style: GoogleFonts.roboto(color: AppPalette.textSecondary, fontSize: 14))),
        Expanded(child: Text(value, style: GoogleFonts.roboto(color: AppPalette.pureWhite, fontSize: 14))),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppPalette.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.roboto(color: AppPalette.pureWhite, fontSize: 14))),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _updateStatus(context, 'accepted'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mark as Accepted', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => _updateStatus(context, 'reviewed'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.pureWhite,
              side: const BorderSide(color: AppPalette.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mark as Reviewed'),
          ),
        ),
      ],
    );
  }
}
