import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';
import '../widgets/domain_filter_row.dart';

class HackathonsTab extends StatefulWidget {
  const HackathonsTab({super.key});

  @override
  State<HackathonsTab> createState() => _HackathonsTabState();
}

class _HackathonsTabState extends State<HackathonsTab> {
  String _selectedDomain = 'All';
  String _selectedMode = 'All'; // All | Online | Offline

  List<Map<String, dynamic>> _allHackathons = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHackathons();
  }

  Future<void> _fetchHackathons() async {
    setState(() => _loading = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('hackathons').get();
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['doc_id'] = d.id;
        return data;
      }).toList();
      if (mounted) {
        setState(() {
          _allHackathons = list;
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
    _filtered = _allHackathons.where((h) {
      final domainMatch = _selectedDomain == 'All' ||
          h['domain']?.toString() == _selectedDomain;
      final modeMatch = _selectedMode == 'All' ||
          h['mode']?.toString().toLowerCase() ==
              _selectedMode.toLowerCase();
      return domainMatch && modeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Domain filter
        DomainFilterRow(
          selected: _selectedDomain,
          onSelected: (d) {
            setState(() {
              _selectedDomain = d;
              _applyFilter();
            });
          },
        ),
        // Mode filter
        _buildModeChips(),
        // Hackathon list
        Expanded(
          child: RefreshIndicator(
            color: AppPalette.pureWhite,
            backgroundColor: AppPalette.surface,
            onRefresh: _fetchHackathons,
            child: _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeChips() {
    final modes = ['All', 'Online', 'Offline'];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = modes[i];
          final sel = _selectedMode == m;
          Color selColor;
          switch (m) {
            case 'Online':
              selColor = Colors.green.shade700;
              break;
            case 'Offline':
              selColor = Colors.orange.shade700;
              break;
            default:
              selColor = AppPalette.pureWhite;
          }
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMode = m;
                _applyFilter();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? selColor : AppPalette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? selColor : AppPalette.border),
              ),
              child: Text(m,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? (m == 'All' ? Colors.black : Colors.white)
                          : AppPalette.textSecondary)),
            ),
          );
        },
      ),
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
            child: Text('No hackathons found.',
                style: GoogleFonts.inter(
                    color: AppPalette.textMuted, fontSize: 15))),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _HackathonCard(hackathon: _filtered[i]),
    );
  }
}

// ─────────────────────────────────────────────
// HACKATHON CARD
// ─────────────────────────────────────────────
class _HackathonCard extends StatelessWidget {
  const _HackathonCard({required this.hackathon});
  final Map<String, dynamic> hackathon;

  Future<void> _launch(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final domain = hackathon['domain']?.toString() ?? '';
    final mode = hackathon['mode']?.toString() ?? '';
    final accentColor = domainColor(domain);
    final isOnline = mode.toLowerCase() == 'online';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppPalette.border),
      ),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: accentColor.withOpacity(0.3),
                          child: Icon(Icons.emoji_events,
                              size: 18, color: accentColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hackathon['title']?.toString() ?? '',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppPalette.pureWhite),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(hackathon['company']?.toString() ?? '',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppPalette.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              hackathon['location']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppPalette.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.shade900.withOpacity(0.5)
                                : Colors.orange.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(mode,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isOnline
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(hackathon['prize']?.toString() ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 13, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Text(
                              'Deadline: ${hackathon['deadline'] ?? '-'}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hackathon['description']?.toString() ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppPalette.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text('Register',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            _launch(hackathon['registration_link']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
