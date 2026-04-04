import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_palette.dart';
import '../../../constants/domains.dart';
import '../../hackathons/screens/hackathon_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'job_detail_screen.dart';
import '../../../widgets/job_feed_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedDomain = 'All';

  @override
  void initState() {
    super.initState();
    _loadPersonalizedFeed();
  }

  List<String> _normalizeDomains(List<String> userDomains) {
    final Map<String, String> mapping = {
      'DevOps': 'Cloud & DevOps',
      'Data Science': 'AI/ML',
      'Mobile Dev': 'Android Development',
      'Mobile Development': 'Android Development',
      'Frontend': 'Web Development',
      'Frontend Development': 'Web Development',
      'Backend': 'Backend Development',
    };

    final Set<String> normalized = {};
    for (var d in userDomains) {
      if (mapping.containsKey(d)) {
        normalized.add(mapping[d]!);
      }
      normalized.add(d); // Also keep original
    }
    return normalized.toList();
  }

  Future<void> _loadPersonalizedFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final rawDomains = List<String>.from(userDoc.data()?['domains'] ?? []);
      final studentDomains = _normalizeDomains(rawDomains);

      // Fetch active jobs (client-side filtering for domains)
      // Sort client-side if missing index, but `.orderBy('posted_at', descending: true)` requires an index on (is_active, posted_at). 
      // Safe fallback: grab all `is_active == true` then sort in Dart.
      // Fetch active jobs
      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .get();

      List<dynamic> jobs = snapshot.docs.map((doc) => doc.data()).toList();
      jobs = jobs.where((job) => job['is_active'] != false).toList();
      
      // Sort by posted_at descending
      jobs.sort((a, b) {
        final t1 = a['posted_at'] as Timestamp?;
        final t2 = b['posted_at'] as Timestamp?;
        if (t1 == null && t2 == null) {
          final id1 = (a['job_id'] ?? 0).toString();
          final id2 = (b['job_id'] ?? 0).toString();
          return id1.compareTo(id2);
        }
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      print("TOTAL JOBS FETCHED: ${jobs.length}");
      for (var job in jobs) {
        print("JOB DOMAIN: ${job['domain']} | TITLE: ${job['title']}");
      }
      print("STUDENT DOMAINS: ${studentDomains}");

      // Filter
      List<dynamic> filtered = [];
      for (var job in jobs) {
        final jobDomain = job['domain'] as String? ?? '';
        if (_selectedDomain == 'All') {
          // Push everything when "All" is active
          filtered.add(job);
        } else {
          if (jobDomain == _selectedDomain) {
            filtered.add(job);
          }
        }
      }

      setState(() {
        _jobs = filtered;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: error = $e');
      setState(() {
        _errorMessage = 'Could not load jobs. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildDomainFilter(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildJobsFeed(),
                  HackathonListScreen(selectedDomain: _selectedDomain),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainFilter() {
    final allDomains = ['All', ...kDomains.map((d) => d['label'] as String)];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: allDomains.length,
        itemBuilder: (context, index) {
          final domain = allDomains[index];
          final bool isSelected = _selectedDomain == domain;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDomain = domain);
                _loadPersonalizedFeed(); // Re-filter jobs locally
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppPalette.pureWhite : AppPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppPalette.pureWhite : AppPalette.pureWhite.withOpacity(0.08),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  domain,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppPalette.background : AppPalette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppPalette.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Prashikshan',
        style: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppPalette.pureWhite,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      bottom: TabBar(
        dividerColor: Colors.transparent,
        indicatorColor: AppPalette.pureWhite,
        labelColor: AppPalette.pureWhite,
        unselectedLabelColor: AppPalette.textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(text: 'Jobs'),
          Tab(text: 'Hackathons'),
        ],
      ),
    );
  }

  Widget _buildJobsFeed() {
    return RefreshIndicator(
      onRefresh: _loadPersonalizedFeed,
      color: AppPalette.textSecondary,
      backgroundColor: AppPalette.card,
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState(_errorMessage)
              : _jobs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) {
                        final job = _jobs[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: JobFeedCard(job: job),
                        ).animate().fadeIn(delay: 50.ms * index).slideX(
                              begin: 0.05,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOutQuint,
                            );
                      },
                    ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.border),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1500.ms,
              color: AppPalette.pureWhite.withOpacity(0.03),
            );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.work,
              size: 52,
              color: AppPalette.textMuted,
            ),
            const SizedBox(height: 20),
            Text(
              'No matching opportunities',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find jobs matching your interests yet. Check back soon or update your preferences.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _refreshRecommendations(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Text(
                  'Refresh Feed',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error,
              size: 48,
              color: AppPalette.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load jobs right now',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppPalette.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _refreshRecommendations(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onJobTapped(dynamic job) {
    // For now, show a simple feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${job['title']} • ${job['company']}'),
        backgroundColor: AppPalette.card,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppPalette.border),
        ),
      ),
    );
  }

  void _refreshRecommendations() {
    _loadPersonalizedFeed();
  }

  Color _brandColor(String company) {
    if (company.contains('Google')) return const Color(0xFF4285F4);
    if (company.contains('Amazon')) return const Color(0xFFFF9900);
    if (company.contains('Flipkart')) return const Color(0xFF2874F0);
    if (company.contains('HCL')) return const Color(0xFF005696);
    if (company.contains('Samsung')) return const Color(0xFF1428A0);
    return AppPalette.textSecondary;
  }
}
