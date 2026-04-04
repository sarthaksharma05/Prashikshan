import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import 'edit_company_profile_screen.dart';

class CompanyProfileTab extends StatefulWidget {
  const CompanyProfileTab({super.key, required this.uid});
  final String uid;

  @override
  State<CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<CompanyProfileTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (doc.exists && mounted) setState(() => _data = doc.data());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launch(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppPalette.pureWhite));
    }
    if (_data == null) {
      return Center(
          child: Text('Profile not found.',
              style: GoogleFonts.inter(color: AppPalette.textMuted)));
    }

    final d = _data!;
    // Support both old onboarding field names and new ones
    final companyName = d['company_name'] ?? d['companyName'] ?? d['name'] ?? 'Company';
    final industry = d['industry'] ?? (d['domains'] != null
        ? (List<String>.from(d['domains'])).join(', ')
        : '');
    final city = d['city'] ?? d['location'] ?? '';
    final size = d['company_size'] ?? d['companySize'] ?? '';
    final website = d['website'] ?? d['websiteUrl'] ?? '';
    final contactPerson = d['contactPerson'] ?? d['name'] ?? '';
    final phone = d['phone'] ?? d['mobileNumber'] ?? '';
    final email = d['email'] ?? '';
    final hiringDomains = List<String>.from(d['hiringDomains'] ?? d['domains'] ?? []);
    final rolesOffered = List<String>.from(d['rolesOffered'] ?? d['hiring_roles'] ?? []);
    final preferredUniversities = List<String>.from(d['preferredUniversities'] ?? []);
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C';

    return RefreshIndicator(
      color: AppPalette.pureWhite,
      backgroundColor: AppPalette.surface,
      onRefresh: _fetchProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── SECTION 1: Hero ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade900,
                  child: Text(initial,
                      style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(companyName,
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.pureWhite),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  [if (industry.isNotEmpty) industry, if (city.isNotEmpty) city]
                      .join(' · '),
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppPalette.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (size.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('$size company',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppPalette.textMuted)),
                ],
                if (website.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _launch(website),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language,
                            size: 15, color: Colors.blue.shade400),
                        const SizedBox(width: 5),
                        Text(website,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.blue.shade300,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── SECTION 2: Contact ───
          _card('Contact Details', [
            _contactRow(Icons.person, 'Contact Person', contactPerson),
            _contactRow(Icons.phone, 'Phone', phone),
            _contactRow(Icons.email, 'Email', email),
          ]),
          const SizedBox(height: 16),

          // ─── SECTION 3: Hiring Preferences ───
          _card('Hiring Preferences', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hiringDomains.isNotEmpty) ...[
                    Text('Domains',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalette.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hiringDomains
                          .map((s) => _chip(s, Colors.blue.shade900))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (rolesOffered.isNotEmpty) ...[
                    Text('Roles Offered',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalette.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          rolesOffered.map((s) => _chip(s, Colors.purple.shade900)).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (preferredUniversities.isNotEmpty) ...[
                    Text('Preferred Universities',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalette.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: preferredUniversities
                          .map((s) => _chip(s, Colors.teal.shade900))
                          .toList(),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (hiringDomains.isEmpty && rolesOffered.isEmpty && preferredUniversities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No preferences set yet.',
                          style: GoogleFonts.inter(
                              color: AppPalette.textMuted)),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ─── Edit Button ───
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: Text('Edit Profile',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.pureWhite,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCompanyProfileScreen(
                      companyData: d,
                      uid: widget.uid,
                    ),
                  ),
                );
                _fetchProfile(); // Refresh on return
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textMuted,
                    letterSpacing: 1.3)),
          ),
          const Divider(height: 1, color: AppPalette.border),
          ...children,
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppPalette.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppPalette.textMuted)),
                Text(value.isEmpty ? 'Not provided' : value,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppPalette.pureWhite)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600)),
    );
  }
}
