import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../models/hackathon_model.dart';
import '../screens/hackathon_detail_screen.dart';

class HackathonCard extends StatefulWidget {
  const HackathonCard({super.key, required this.hackathon});
  final Hackathon hackathon;

  @override
  State<HackathonCard> createState() => _HackathonCardState();
}

class _HackathonCardState extends State<HackathonCard> {
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
    
    final hackId = widget.hackathon.id.toString();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('student_uid', isEqualTo: _currentStudentUid)
          .where('item_id', isEqualTo: hackId)
          .where('type', isEqualTo: 'hackathon')
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

  Future<void> _handleRegister() async {
    final hackathon = widget.hackathon;
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
                'Register for ${hackathon.title}?',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.pureWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${hackathon.company} · ${hackathon.location}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your profile will be shared with ${hackathon.company}. You will be notified by email with further details about the hackathon. 🏆',
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
                        backgroundColor: Colors.amber,
                        foregroundColor: AppPalette.secondaryA,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Confirm'),
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
      _processRegistration();
    }
  }

  Future<void> _processRegistration() async {
    setState(() => _isLoading = true);
    
    final hackathon = widget.hackathon;
    final hackId = hackathon.id.toString();

    // Determine the company uid from hackathons collection if possible, else we might not have it unless it's in the hackathon model
    // Wait, the hackathon model might not have "posted_by_uid" in its schema yet? Let's fix that.
    // Actually, I can fetch the hackathon document manually using its ID to get `posted_by_uid`.
    String companyUid = '';
    try {
      final query = await FirebaseFirestore.instance.collection('hackathons').where('id', isEqualTo: hackathon.id).get();
      if (query.docs.isNotEmpty) {
        companyUid = query.docs.first.data()['posted_by_uid'] ?? '';
      }
    } catch (_) {}

    try {
      final studentDocRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentStudentUid)
          .get();

      if (!studentDocRef.exists) throw Exception('Student profile not found');
      
      final studentDoc = studentDocRef.data()!;

      // Create enrollment record
      final enrollmentRef = await FirebaseFirestore.instance.collection('enrollments').add({
        'type': 'hackathon',
        'item_id': hackId,
        'item_title': hackathon.title,
        'item_domain': hackathon.domain,
        'company_name': hackathon.company,
        'company_uid': companyUid,
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
      if (companyUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'company_uid': companyUid,
          'enrollment_id': enrollmentRef.id,
          'type': 'hackathon_enrollment',
          'student_name': studentDoc['name'] ?? 'A student',
          'item_title': hackathon.title,
          'item_domain': hackathon.domain,
          'message': '${studentDoc['name'] ?? 'A student'} registered for ${hackathon.title}',
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
          SnackBar(content: Text('Registration submitted! You will be notified soon by mail from ${hackathon.company}. 🏆')),
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

  @override
  Widget build(BuildContext context) {
    bool isEndingSoon = _checkIsEndingSoon(widget.hackathon.deadline);
    final hackathon = widget.hackathon;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HackathonDetailScreen(hackathon: hackathon),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppPalette.pureWhite.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'hack_title_${hackathon.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            hackathon.title,
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.pureWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hackathon.company,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEndingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Ending Soon',
                      style: GoogleFonts.roboto(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              hackathon.description,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppPalette.textMuted,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _InfoBadge(
                  icon: Icons.emoji_events_outlined,
                  label: hackathon.prize,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                _InfoBadge(
                  icon: Icons.laptop_chromebook_outlined,
                  label: hackathon.mode,
                  color: Colors.blueAccent,
                ),
                const Spacer(),
                Text(
                  hackathon.deadline,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
            if (hackathon.teamSize.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: AppPalette.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Team Size: ${hackathon.teamSize}',
                    style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textSecondary),
                  ),
                ],
              ),
            ],
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
                          child: Text('✓ Registered', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.bold)),
                        )
                      : ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: AppPalette.secondaryA,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Register Now', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  final url = Uri.parse(hackathon.registrationLink);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text('Visit Website', style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _checkIsEndingSoon(String deadline) {
    try {
      final DateTime date = DateTime.parse(deadline);
      final DateTime now = DateTime.now();
      final Duration diff = date.difference(now);
      return diff.inDays >= 0 && diff.inDays <= 7;
    } catch (e) {
      return false;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.secondaryA.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPalette.pureWhite.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
