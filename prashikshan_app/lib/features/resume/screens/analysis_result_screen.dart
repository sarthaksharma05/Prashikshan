import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/analysis_result.dart';
import '../../../core/theme/app_palette.dart';

class AnalysisResultScreen extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Force premium black
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Match Audit',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _buildHeroScore(),
            const SizedBox(height: 48),
            _buildSkillAlignment(),
            const SizedBox(height: 32),
            _buildInsightSection('STRENGTHS', result.strengths, const Color(0xFF111111)),
            const SizedBox(height: 24),
            _buildInsightSection('AREAS FOR IMPROVEMENT', result.weaknesses, const Color(0xFF111111)),
            const SizedBox(height: 24),
            _buildInsightSection('EXECUTIVE SUGGESTIONS', result.suggestions, const Color(0xFF111111)),
            const SizedBox(height: 24),
            _buildInsightSection('PROJECT & EXPERIENCE AUDIT', result.projectFeedback, const Color(0xFF111111)),
            const SizedBox(height: 32),
            _buildNewAnalysisButton(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAnalysisButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            "ANALYZE ANOTHER RESUME",
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 1600.ms);
  }

  Widget _buildHeroScore() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: result.score / 100,
                strokeWidth: 4,
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ).animate().rotate(duration: 1500.ms, curve: Curves.easeOutExpo),
            Column(
              children: [
                Text(
                  '${result.score}',
                  style: GoogleFonts.roboto(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  'COMPATIBILITY SCORE',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ).animate().scale(delay: 500.ms, duration: 800.ms, curve: Curves.elasticOut),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            result.overallScoreReason.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.6,
              letterSpacing: 0.5,
              color: Colors.grey[400],
            ),
          ),
        ).animate().fadeIn(delay: 1000.ms),
      ],
    );
  }

  Widget _buildSkillAlignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILL ALIGNMENT',
          style: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...result.matchedSkills.map((s) => _buildSkillChip(s, true)),
            ...result.missingSkills.map((s) => _buildSkillChip(s, false)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSkillChip(String label, bool matched) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: matched ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: matched ? Colors.white : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInsightSection(String title, List<String> items, Color cardColor) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[300],
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.05, end: 0);
  }
}
