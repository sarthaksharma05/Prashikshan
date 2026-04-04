import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_palette.dart';
import 'enrollment_detail_screen.dart';

class NotificationsTab extends StatelessWidget {
  final String companyUid;

  const NotificationsTab({super.key, required this.companyUid});

  Future<void> _markAllRead() async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('company_uid', isEqualTo: companyUid)
        .where('is_read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppPalette.background,
            floating: true,
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppPalette.pureWhite,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _markAllRead,
                child: Text('Mark all read', style: GoogleFonts.roboto(color: Colors.blueAccent)),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('company_uid', isEqualTo: companyUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Error loading notifications', style: TextStyle(color: Colors.red))),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['created_at'];
                final bTime = bData['created_at'];
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return (bTime as Timestamp).compareTo(aTime as Timestamp);
              });

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none, size: 48, color: AppPalette.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet.',
                          style: GoogleFonts.roboto(color: AppPalette.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isRead = data['is_read'] ?? false;
                    final isJob = data['type'] == 'job_enrollment';
                    final date = data['created_at'] as Timestamp?;
                    final timeString = date != null ? timeago.format(date.toDate()) : 'Recently';

                    return ListTile(
                      tileColor: isRead ? AppPalette.background : Colors.blue.withOpacity(0.05),
                      leading: CircleAvatar(
                        backgroundColor: isJob ? Colors.blue.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                        child: Icon(
                          isJob ? Icons.work : Icons.emoji_events,
                          color: isJob ? Colors.blueAccent : Colors.amberAccent,
                        ),
                      ),
                      title: Text(
                        data['message'] ?? 'Notification',
                        style: GoogleFonts.roboto(
                          color: AppPalette.pureWhite,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppPalette.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data['item_domain'] ?? 'Domain',
                                style: GoogleFonts.roboto(fontSize: 10, color: AppPalette.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(timeString, style: GoogleFonts.roboto(fontSize: 11, color: AppPalette.textMuted)),
                          ],
                        ),
                      ),
                      trailing: isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () async {
                        if (!isRead) {
                          FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(docs[index].id)
                              .update({'is_read': true});
                        }

                        final enrollmentId = data['enrollment_id'];
                        if (enrollmentId != null) {
                          final eDoc = await FirebaseFirestore.instance.collection('enrollments').doc(enrollmentId).get();
                          if (eDoc.exists && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EnrollmentDetailScreen(
                                  enrollment: eDoc.data()!,
                                  enrollmentId: enrollmentId,
                                  companyUid: companyUid,
                                ),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
