import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../models/hackathon_model.dart';

class HackathonDetailScreen extends StatelessWidget {
  const HackathonDetailScreen({super.key, required this.hackathon});
  final Hackathon hackathon;

  Future<void> _launchUrl(BuildContext context) async {
    final Uri url = Uri.parse(hackathon.registrationLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open registration link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildContent(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      backgroundColor: AppPalette.background,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppPalette.pureWhite,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF161B22),
                    Color(0xFF0D1117),
                  ],
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'hack_title_${hackathon.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    hackathon.title,
                    style: GoogleFonts.roboto(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.pureWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyInfo(),
          const SizedBox(height: 32),
          _buildOverviewGrid(),
          const SizedBox(height: 32),
          _buildDescription(),
          const SizedBox(height: 32),
          _buildTags(),
          const SizedBox(height: 100), // Extra space for bottom bar
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ORGANIZED BY',
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hackathon.company,
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppPalette.pureWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _buildInfoItem(Icons.emoji_events_outlined, 'Prizes', hackathon.prize, Colors.amber),
        _buildInfoItem(Icons.laptop_chromebook_outlined, 'Mode', hackathon.mode, Colors.blueAccent),
        _buildInfoItem(Icons.calendar_month_outlined, 'Deadline', hackathon.deadline, Colors.redAccent),
        _buildInfoItem(Icons.location_on_outlined, 'Location', hackathon.location, Colors.greenAccent),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.pureWhite.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(fontSize: 10, color: AppPalette.textMuted, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.pureWhite, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABOUT THE CHALLENGE',
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hackathon.description,
          style: GoogleFonts.roboto(
            fontSize: 15,
            color: AppPalette.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 10,
      children: [
        _buildTag(hackathon.domain),
        _buildTag(hackathon.mode),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.pureWhite.withOpacity(0.05),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppPalette.pureWhite.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppPalette.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppPalette.background,
        border: Border(top: BorderSide(color: AppPalette.pureWhite.withOpacity(0.08))),
      ),
      child: ElevatedButton(
        onPressed: () => _launchUrl(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.pureWhite,
          foregroundColor: AppPalette.background,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          'Register Now',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
