import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import 'post_job_form.dart';
import 'post_hackathon_form.dart';

class PostChooserSheet extends StatefulWidget {
  final String uid;

  const PostChooserSheet({super.key, required this.uid});

  @override
  State<PostChooserSheet> createState() => _PostChooserSheetState();
}

class _PostChooserSheetState extends State<PostChooserSheet> {
  // 'job' or 'hackathon'
  String _selectedType = 'job';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false, // Ensures it has a background
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppPalette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Segmented Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = 'job'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedType == 'job'
                                  ? AppPalette.pureWhite
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 16,
                                  color: _selectedType == 'job'
                                      ? AppPalette.background
                                      : AppPalette.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Post a Job',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedType == 'job'
                                        ? AppPalette.background
                                        : AppPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = 'hackathon'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedType == 'hackathon'
                                  ? AppPalette.pureWhite
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 16,
                                  color: _selectedType == 'hackathon'
                                      ? AppPalette.background
                                      : AppPalette.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Post a Hackathon',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedType == 'hackathon'
                                        ? AppPalette.background
                                        : AppPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Form Switcher
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedType == 'job'
                      ? PostJobForm(uid: widget.uid, scrollController: scrollController)
                      : PostHackathonForm(uid: widget.uid, scrollController: scrollController),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
