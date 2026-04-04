import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_palette.dart';
import '../features/home/screens/job_detail_screen.dart';

class JobFeedCard extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobFeedCard({super.key, required this.job});

  @override
  State<JobFeedCard> createState() => _JobFeedCardState();
}

class _JobFeedCardState extends State<JobFeedCard> {
  bool _isLoading = true;
  bool _hasEnrolled = false;
  String _currentStudentUid = '';

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    _currentStudentUid = uid;
    
    final jobIdVar = widget.job['id'] ?? widget.job['job_id'];
    final String jobId = jobIdVar?.toString() ?? '';

    if (jobId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('student_uid', isEqualTo: _currentStudentUid)
          .where('item_id', isEqualTo: jobId)
          .where('type', isEqualTo: 'job')
          .get();

      if (mounted) {
        setState(() {
          _hasEnrolled = snap.docs.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApply() async {
    // Show confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply for ${widget.job['title']}?',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.pureWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.job['company']} · ${widget.job['location']}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your profile will be shared with ${widget.job['company']}. You will be notified by email once the company reviews your application.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppPalette.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.pureWhite,
                        side: BorderSide(color: AppPalette.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: AppPalette.pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Confirm & Apply'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      _processEnrollment();
    }
  }

  Future<void> _processEnrollment() async {
    setState(() => _isLoading = true);
    
    final jobIdVar = widget.job['id'] ?? widget.job['job_id'];
    final String jobId = jobIdVar?.toString() ?? '';

    try {
      final studentDocRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentStudentUid)
          .get();

      if (!studentDocRef.exists) throw Exception('Student profile not found');
      
      final studentDoc = studentDocRef.data()!;

      // Create enrollment record
      final enrollmentRef = await FirebaseFirestore.instance.collection('enrollments').add({
        'type': 'job',
        'item_id': jobId,
        'item_title': widget.job['title'] ?? '',
        'item_domain': widget.job['domain'] ?? '',
        'company_name': widget.job['company'] ?? '',
        'company_uid': widget.job['posted_by_uid'] ?? '',
        'student_uid': _currentStudentUid,
        'student_name': studentDoc['name'] ?? '',
        'student_email': studentDoc['email'] ?? '',
        'student_phone': studentDoc['mobileNumber'] ?? '',
        'student_university': studentDoc['university'] ?? '',
        'student_cgpa': studentDoc['cgpa']?.toString() ?? '',
        'student_projects_count': studentDoc['projects_count'] ?? 0,
        'student_domains': studentDoc['domains'] ?? [],
        'student_githubUrl': studentDoc['githubUrl'] ?? '',
        'student_linkedinUrl': studentDoc['linkedinUrl'] ?? '',
        'student_lookingFor': studentDoc['lookingFor'] ?? '',
        'student_level': studentDoc['level'] ?? '',
        'student_role': studentDoc['role'] ?? '',
        'enrolled_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Create notification for company
      if (widget.job['posted_by_uid'] != null && widget.job['posted_by_uid'].toString().isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'company_uid': widget.job['posted_by_uid'],
          'enrollment_id': enrollmentRef.id,
          'type': 'job_enrollment',
          'student_name': studentDoc['name'] ?? 'A student',
          'item_title': widget.job['title'] ?? '',
          'item_domain': widget.job['domain'] ?? '',
          'message': '${studentDoc['name'] ?? 'A student'} applied for ${widget.job['title'] ?? 'this job'}',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          _hasEnrolled = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application submitted! You will be notified soon by mail from ${widget.job['company']}. 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  Color _brandColor(String name) {
    if (name.isEmpty) return AppPalette.pureWhite;
    final int code = name.codeUnitAt(0);
    final colors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];
    return colors[code % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(
              job: job,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'job_card_${job['job_id']}',
        flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
        ) {
          return SingleChildScrollView(
            child: fromHeroContext.widget,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppPalette.pureWhite.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _brandColor(job['company'] ?? '').withOpacity(0.2),
                    child: Text(
                      (job['company'] ?? 'C')[0].toUpperCase(),
                      style: TextStyle(color: _brandColor(job['company'] ?? ''), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? 'Role Title',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job['company'] ?? 'Company',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppPalette.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppPalette.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              job['location'] ?? 'Remote',
                              style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job['domain'] ?? 'Domain',
                      style: GoogleFonts.roboto(fontSize: 10, color: AppPalette.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (job['skills'] != null && (job['skills'] as List).isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (job['skills'] as List).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppPalette.card,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.toString(),
                      style: GoogleFonts.roboto(fontSize: 11, color: AppPalette.textSecondary),
                    ),
                  )).toList(),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${job['type'] ?? 'Job'} · ${job['experience_level'] ?? 'Entry'}',
                    style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textMuted),
                  ),
                  if (job['salary'] != null && job['salary'].toString().trim().isNotEmpty)
                    Text(
                      job['salary'],
                      style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: _isLoading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)))
                    : _hasEnrolled
                        ? ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: AppPalette.surfaceLight,
                              disabledForegroundColor: AppPalette.textSecondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('✓ Applied', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton(
                            onPressed: _handleApply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: AppPalette.pureWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Apply Now', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
