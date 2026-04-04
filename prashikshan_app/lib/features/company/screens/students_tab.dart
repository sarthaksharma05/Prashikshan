import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_palette.dart';
import '../../../services/api_service.dart';
import '../widgets/domain_filter_row.dart';
import '../widgets/student_detail_card.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  // Use the global baseUrl
  String get _base => ApiService.baseUrl;

  // Filter state
  String _selectedDomain = 'All';
  String _selectedMode = 'Top Students'; // or 'By University'
  String _selectedUniversity = 'All';
  String _sortBy = 'Score (High to Low)';

  List<String> _universities = [];
  List<Map<String, dynamic>> _students = [];
  bool _loading = false;

  static const _sortOptions = [
    'Score (High to Low)',
    'CGPA (High to Low)',
    'Projects (High to Low)',
    'Name (A–Z)',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUniversities();
    _fetchStudents();
  }

  Future<void> _fetchUniversities() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/students/universities'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() =>
              _universities = List<String>.from(data['universities'] ?? []));
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    final uni =
        _selectedMode == 'By University' ? _selectedUniversity : 'All';
    try {
      final res = await http
          .post(
            Uri.parse('$_base/students/ranked'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'domain': _selectedDomain,
              'university': uni,
              'top_n': 30,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _students =
              list.map((e) => Map<String, dynamic>.from(e)).toList();
          _applySort();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching students: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySort() {
    switch (_sortBy) {
      case 'CGPA (High to Low)':
        _students.sort((a, b) {
          double ca = 0, cb = 0;
          try { ca = double.parse(a['cgpa'].toString()); } catch (_) {}
          try { cb = double.parse(b['cgpa'].toString()); } catch (_) {}
          return cb.compareTo(ca);
        });
        break;
      case 'Projects (High to Low)':
        _students.sort((a, b) =>
            (b['projects_count'] as num? ?? 0)
                .compareTo(a['projects_count'] as num? ?? 0));
        break;
      case 'Name (A–Z)':
        _students.sort((a, b) =>
            (a['name']?.toString() ?? '')
                .compareTo(b['name']?.toString() ?? ''));
        break;
      default: // Score — already sorted by API
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ROW 1 — Domain filter
        DomainFilterRow(
          selected: _selectedDomain,
          onSelected: (d) {
            setState(() => _selectedDomain = d);
            _fetchStudents();
          },
        ),
        // ROW 2 — Mode toggle
        _buildModeToggle(),
        // ROW 3 — University filter (only in By University mode)
        if (_selectedMode == 'By University') _buildUniversityChips(),
        // ROW 4 — Sort dropdown
        _buildSortRow(),
        // Student list
        Expanded(
          child: RefreshIndicator(
            color: AppPalette.pureWhite,
            backgroundColor: AppPalette.surface,
            onRefresh: _fetchStudents,
            child: _buildStudentList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: ['Top Students', 'By University'].map((mode) {
          final sel = _selectedMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMode = mode);
                _fetchStudents();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                    right: mode == 'Top Students' ? 6 : 0,
                    left: mode == 'By University' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppPalette.pureWhite : AppPalette.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          sel ? AppPalette.pureWhite : AppPalette.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode == 'Top Students' ? Icons.emoji_events_outlined : Icons.school_outlined,
                      size: 16,
                      color: sel ? Colors.black : AppPalette.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.black : AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUniversityChips() {
    final all = ['All', ..._universities];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final u = all[i];
          final sel = _selectedUniversity == u;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedUniversity = u);
              _fetchStudents();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? Colors.blue.shade800 : AppPalette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        sel ? Colors.blue.shade600 : AppPalette.border),
              ),
              child: Text(u,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppPalette.textSecondary,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.only(right: 14, bottom: 4, left: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Sort by: ',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppPalette.textMuted)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              dropdownColor: AppPalette.surface,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppPalette.textSecondary,
                  fontWeight: FontWeight.w600),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppPalette.textMuted, size: 18),
              items: _sortOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _sortBy = v;
                  _applySort();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppPalette.pureWhite));
    }
    if (_students.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text('No students found.',
                style: GoogleFonts.inter(
                    color: AppPalette.textMuted, fontSize: 15)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _students.length,
      itemBuilder: (_, i) => StudentDetailCard(
        student: _students[i],
        rank: _students[i]['rank'] as int? ?? i + 1,
      ),
    );
  }
}
