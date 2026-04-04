import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_palette.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        title: Text(
          'My Applications',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.pureWhite),
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('enrollments')
            .where('student_uid', isEqualTo: uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading applications.', style: TextStyle(color: Colors.red)));
          }

          final docs = snapshot.data?.docs ?? [];
          
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['enrolled_at'];
            final bTime = bData['enrolled_at'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return (bTime as Timestamp).compareTo(aTime as Timestamp);
          });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "You haven't applied to anything yet.\nStart exploring jobs and hackathons! 🚀",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: AppPalette.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isJob = data['type'] == 'job';
              final status = data['status'] ?? 'pending';

              return Container(
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isJob ? Colors.blue.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                        child: Icon(
                          isJob ? Icons.work : Icons.emoji_events,
                          color: isJob ? Colors.blueAccent : Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['item_title'] ?? 'Title',
                              style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold, color: AppPalette.pureWhite),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['company_name'] ?? 'Company',
                              style: GoogleFonts.roboto(fontSize: 13, color: AppPalette.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Applied: ${_formatDate(data['enrolled_at'] as Timestamp?)}',
                              style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              status.toUpperCase(),
                              style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                            ),
                            if (status.toLowerCase() == 'accepted') ...[
                              const SizedBox(width: 4),
                              const Text('🎉', style: TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
