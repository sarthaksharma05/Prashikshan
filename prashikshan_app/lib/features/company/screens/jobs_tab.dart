import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';
import '../widgets/domain_filter_row.dart';
import 'job_detail_screen.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  String _selectedDomain = 'All';
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _loading = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('jobs').get();
      final jobs = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['doc_id'] = d.id;
        return data;
      }).toList();
      if (mounted) {
        setState(() {
          _allJobs = jobs;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_selectedDomain == 'All') {
      _filtered = List.from(_allJobs);
    } else {
      _filtered = _allJobs
          .where((j) => j['domain']?.toString() == _selectedDomain)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DomainFilterRow(
          selected: _selectedDomain,
          onSelected: (d) {
            setState(() {
              _selectedDomain = d;
              _applyFilter();
            });
          },
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppPalette.pureWhite,
            backgroundColor: AppPalette.surface,
            onRefresh: _fetchJobs,
            child: _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppPalette.pureWhite));
    }
    if (_filtered.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(
            child: Text('No jobs found for this domain.',
                style: GoogleFonts.inter(
                    color: AppPalette.textMuted, fontSize: 15))),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _JobCard(job: _filtered[i]),
    );
  }
}

// ─────────────────────────────────────────────
// JOB CARD
// ─────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final skills = List<String>.from(job['skills'] ?? []);
    final domain = job['domain']?.toString() ?? '';
    final avatarColor = domainColor(domain);
    final company = job['company']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        color: AppPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppPalette.border),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor,
                    child: Text(
                      company.isNotEmpty ? company[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job['title']?.toString() ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.pureWhite),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(company,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.blue.shade300,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                  job['location']?.toString() ?? '',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppPalette.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.category,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(domain,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppPalette.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppPalette.textMuted),
                ],
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: skills
                      .take(6)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppPalette.textSecondary)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
