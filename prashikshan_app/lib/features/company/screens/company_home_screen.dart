import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_palette.dart';
import '../widgets/student_rank_card.dart';

class CompanyHomeScreen extends StatefulWidget {
  final String uid;
  const CompanyHomeScreen({super.key, required this.uid});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _base = 'http://10.28.94.5:8000';

  late TabController _tabController;
  String _companyName = 'Company';
  String _selectedDomain = 'All';
  String _selectedUniversity = 'All';
  List<String> _universities = [];
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  static const List<String> _domains = [
    'All', 'Technology', 'Data Science', 'Marketing', 'Finance',
    'Design', 'Operations', 'Business Development', 'Analytics',
    'Blockchain', 'AI/ML',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchCompanyName(), _fetchUniversities()]);
    await _fetchRanked();
  }

  Future<void> _fetchCompanyName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists) setState(() => _companyName = doc['companyName'] ?? doc['name'] ?? 'Company');
    } catch (_) {}
  }

  Future<void> _fetchUniversities() async {
    try {
      final res = await http.get(Uri.parse('$_base/students/universities')).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _universities = List<String>.from(data['universities']));
      }
    } catch (_) {}
  }

  Future<void> _fetchRanked() async {
    setState(() => _loading = true);
    try {
      final uni = _tabController.index == 1 ? _selectedUniversity : 'All';
      final res = await http.post(
        Uri.parse('$_base/students/ranked'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'domain': _selectedDomain, 'university': uni, 'top_n': 20}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() => _students = list.map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prashikshan for Companies',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w900, fontSize: 16, color: AppPalette.pureWhite)),
            Text(_companyName,
                style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppPalette.textSecondary),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Section A — Domain filter chips
          _buildDomainChips(),
          // Tab toggle
          _buildTabToggle(),
          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildDomainChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = _domains[i];
          final sel = _selectedDomain == d;
          return ChoiceChip(
            label: Text(d),
            selected: sel,
            onSelected: (_) {
              setState(() => _selectedDomain = d);
              _fetchRanked();
            },
            selectedColor: AppPalette.pureWhite,
            backgroundColor: AppPalette.surface,
            labelStyle: GoogleFonts.roboto(
              color: sel ? Colors.black : AppPalette.textSecondary,
              fontSize: 12, fontWeight: FontWeight.w700,
            ),
            side: BorderSide(color: sel ? AppPalette.pureWhite : AppPalette.border),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => _fetchRanked(),
        indicator: BoxDecoration(color: AppPalette.pureWhite, borderRadius: BorderRadius.circular(10)),
        labelColor: Colors.black,
        unselectedLabelColor: AppPalette.textSecondary,
        labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w800, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '🏆  Top Students'),
          Tab(text: '🏫  By University'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildStudentList(),
        Column(
          children: [
            _buildUniversityChips(),
            Expanded(child: _buildStudentList()),
          ],
        ),
      ],
    );
  }

  Widget _buildUniversityChips() {
    final all = ['All', ..._universities];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final u = all[i];
          final sel = _selectedUniversity == u;
          return ChoiceChip(
            label: Text(u),
            selected: sel,
            onSelected: (_) {
              setState(() => _selectedUniversity = u);
              _fetchRanked();
            },
            selectedColor: Colors.blue.shade800,
            backgroundColor: AppPalette.surface,
            labelStyle: GoogleFonts.roboto(
              color: sel ? Colors.white : AppPalette.textSecondary,
              fontSize: 11, fontWeight: FontWeight.w700,
            ),
            side: BorderSide(color: sel ? Colors.blue : AppPalette.border),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildStudentList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppPalette.pureWhite));
    if (_students.isEmpty) {
      return Center(
        child: Text('No students found for this domain.',
            style: GoogleFonts.roboto(color: AppPalette.textMuted, fontSize: 15)),
      );
    }
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (_, i) => StudentRankCard(student: _students[i], rank: _students[i]['rank'] as int),
    );
  }
}
