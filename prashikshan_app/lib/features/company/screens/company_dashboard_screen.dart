import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/models/user_model.dart';
import '../../onboarding/services/user_service.dart';
import '../widgets/student_card.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  String _selectedDomain = 'All Domains';
  String _selectedUniversity = 'All Universities';
  bool _sortByTopStudents = false;

  final List<String> _domains = [
    'All Domains', 'AI/ML', 'Web Development', 'Android Development',
    'UI/UX Design', 'Backend Development', 'Data Engineering',
    'Cloud & DevOps', 'Cybersecurity', 'Blockchain', 'Game Development'
  ];

  final List<String> _universities = [
    'All Universities', 'IIT Delhi', 'BITS Pilani', 'VIT Vellore',
    'NIT Trichy', 'IIT Bombay', 'IIIT Hyderabad', 'SRM University',
    'Delhi University', 'Lovely Professional University', 'Chandigarh University'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilters(),
          _buildRankingToggle(),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppPalette.background,
      elevation: 0,
      title: Text(
        'Talent Pipeline',
        style: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppPalette.pureWhite,
          letterSpacing: -1,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout_rounded, color: AppPalette.textSecondary),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _domains.map((domain) => _buildDomainChip(domain)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUniversity,
                  dropdownColor: AppPalette.surface,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppPalette.textSecondary),
                  isExpanded: true,
                  style: GoogleFonts.roboto(
                    color: AppPalette.pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (val) => setState(() => _selectedUniversity = val!),
                  items: _universities.map((uni) {
                    return DropdownMenuItem(value: uni, child: Text(uni));
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainChip(String domain) {
    final bool isSelected = _selectedDomain == domain;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(domain),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedDomain = domain);
        },
        selectedColor: AppPalette.pureWhite,
        backgroundColor: AppPalette.surface,
        labelStyle: GoogleFonts.roboto(
          color: isSelected ? Colors.black : AppPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isSelected ? AppPalette.pureWhite : AppPalette.border),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildRankingToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Top Talent Sorting',
                style: GoogleFonts.roboto(
                  color: AppPalette.pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Switch(
            value: _sortByTopStudents,
            activeColor: Colors.amber,
            onChanged: (val) => setState(() => _sortByTopStudents = val),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<List<UserModel>>(
      stream: UserService().getStudentUsers(
        domainFilter: _selectedDomain,
        universityFilter: _selectedUniversity,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppPalette.pureWhite));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        List<UserModel> students = snapshot.data!;

        if (_sortByTopStudents) {
          students.sort((a, b) {
            final double scoreA = (a.projects.length * 2.0) + (double.tryParse(a.cgpa ?? '0.0') ?? 0.0);
            final double scoreB = (b.projects.length * 2.0) + (double.tryParse(b.cgpa ?? '0.0') ?? 0.0);
            return scoreB.compareTo(scoreA); // Descending order
          });
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: students.length,
          itemBuilder: (context, index) {
            return StudentCard(student: students[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, color: AppPalette.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No matching candidates',
            style: GoogleFonts.roboto(color: AppPalette.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
