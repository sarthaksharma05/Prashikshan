import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../models/hackathon_model.dart';
import '../widgets/hackathon_card.dart';

class HackathonListScreen extends StatefulWidget {
  final String selectedDomain;

  const HackathonListScreen({super.key, this.selectedDomain = 'All'});

  @override
  State<HackathonListScreen> createState() => _HackathonListScreenState();
}

class _HackathonListScreenState extends State<HackathonListScreen> {
  List<Hackathon> _hackathons = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHackathons();
  }

  @override
  void didUpdateWidget(HackathonListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDomain != widget.selectedDomain) {
      _loadHackathons();
    }
  }

  Future<void> _loadHackathons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hackathons')
          .get();

      List<dynamic> docs = snapshot.docs.map((doc) => doc.data()).toList();
      docs = docs.where((doc) => doc['is_active'] != false).toList();

      // Client-side sort by posted_at descending if exists
      docs.sort((a, b) {
        final t1 = a['posted_at'] as Timestamp?;
        final t2 = b['posted_at'] as Timestamp?;
        if (t1 == null && t2 == null) {
          final id1 = (a['id'] ?? 0).toString();
          final id2 = (b['id'] ?? 0).toString();
          return id1.compareTo(id2);
        }
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      // Client-side filter
      List<Hackathon> filtered = [];
      for (var doc in docs) {
        final hDomain = doc['domain'] as String? ?? '';
        if (widget.selectedDomain == 'All' || hDomain == widget.selectedDomain) {
          filtered.add(Hackathon.fromMap(doc as Map<String, dynamic>));
        }
      }

      setState(() {
        _hackathons = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading hackathons.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildHackathonList(),
        ),
      ],
    );
  }

  Widget _buildHackathonList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _buildInfoState(_errorMessage, Icons.error_outline);
    }

    if (_hackathons.isEmpty) {
      return _buildInfoState('No hackathons found in ${widget.selectedDomain}', Icons.search_off_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _hackathons.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: HackathonCard(hackathon: _hackathons[index]),
        ).animate().fadeIn(delay: 50.ms * index).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildInfoState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppPalette.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              color: AppPalette.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
