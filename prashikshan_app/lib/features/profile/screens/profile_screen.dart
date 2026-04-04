import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/models/user_model.dart';
import '../../onboarding/services/user_service.dart';
import 'edit_profile_screen.dart';
import 'add_project_screen.dart';
import 'my_applications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppRouter()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Portfolio',
          style: GoogleFonts.roboto(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppPalette.pureWhite, size: 22),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                final userModel = await UserService().getUserProfile(uid);
                if (userModel != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        initialData: userModel.toMap(),
                        uid: uid,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppPalette.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: UserService().getUserProfileStream(FirebaseAuth.instance.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppPalette.pureWhite));
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState(context);
          }

          final user = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              _buildMyApplicationsButton(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Professional Presence'),
              const SizedBox(height: 12),
              _buildSocialsSection(user),
              const SizedBox(height: 24),
              _buildSectionTitle('Project Portfolio'),
              const SizedBox(height: 12),
              _buildProjectsSection(context, user),
              const SizedBox(height: 24),
              _buildSectionTitle('Career Asset'),
              const SizedBox(height: 12),
              _buildResumeSection(context, user),
              const SizedBox(height: 24),
              _buildSectionTitle('Academic Background'),
              const SizedBox(height: 12),
              _buildAcademicGrid(user),
              const SizedBox(height: 24),
              _buildSectionTitle('Career Intent'),
              const SizedBox(height: 12),
              _buildIntentCard(user),
              const SizedBox(height: 24),
              _buildSectionTitle('Expertise'),
              const SizedBox(height: 12),
              _buildExpertiseCard(user),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppPalette.textMuted,
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.surfaceLight,
              border: Border.all(color: AppPalette.pureWhite.withOpacity(0.1), width: 1),
              image: user.profilePhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(user.profilePhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.profilePhotoUrl == null
                ? const Icon(Icons.person_outline_rounded, color: AppPalette.pureWhite, size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppPalette.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildAcademicGrid(UserModel user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildInfoTile('University', user.university ?? 'Not set', Icons.school_outlined),
        _buildInfoTile('CGPA', user.cgpa ?? '0.0', Icons.analytics_outlined),
        _buildInfoTile('Experience', user.level, Icons.trending_up_rounded),
        _buildInfoTile('Contact', user.mobileNumber ?? 'Not set', Icons.smartphone_rounded),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppPalette.textSecondary),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.pureWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildMyApplicationsButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_rounded, color: Colors.blueAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Applications', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.pureWhite)),
                  const SizedBox(height: 2),
                  Text('View jobs and hackathons you applied to', style: GoogleFonts.roboto(fontSize: 12, color: AppPalette.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppPalette.textMuted),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildIntentCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_outlined, color: AppPalette.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Looking for',
                  style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.textMuted),
                ),
                Text(
                  user.lookingFor,
                  style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.pureWhite),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSocialsSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSocialItem('LinkedIn', user.linkedinUrl, Icons.link_rounded),
          Container(width: 1, height: 24, color: AppPalette.border),
          _buildSocialItem('GitHub', user.githubUrl, Icons.code_rounded),
        ],
      ),
    );
  }

  Widget _buildSocialItem(String label, String? url, IconData icon) {
    final bool isSet = url != null && url.isNotEmpty;
    return Opacity(
      opacity: isSet ? 1.0 : 0.4,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppPalette.pureWhite),
          const SizedBox(width: 10),
          Text(
            isSet ? label : 'Not linked',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPalette.pureWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(BuildContext context, UserModel user) {
    final projects = user.projects;

    return Column(
      children: [
        if (projects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.border, style: BorderStyle.none),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open_outlined, color: AppPalette.textMuted, size: 32),
                const SizedBox(height: 12),
                Text('No projects added yet', style: GoogleFonts.roboto(color: AppPalette.textMuted)),
              ],
            ),
          )
        else
          ...projects.map((project) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project['title'] ?? 'Untitled Project',
                              style: GoogleFonts.roboto(
                                  fontSize: 17, fontWeight: FontWeight.w800, color: AppPalette.pureWhite),
                            ),
                          ),
                          if (project['github_link'] != null && project['github_link'].isNotEmpty)
                            Icon(Icons.open_in_new_rounded, size: 18, color: AppPalette.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project['description'] ?? 'No description provided.',
                        style: GoogleFonts.roboto(fontSize: 14, height: 1.4, color: AppPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
              )),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProjectScreen(
                    initialData: user.toMap(),
                    uid: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add a new Project'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.pureWhite,
              side: BorderSide(color: AppPalette.pureWhite.withOpacity(0.1)),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeSection(BuildContext context, UserModel user) {
    final bool hasResume =
        user.resumeUrl != null && user.resumeUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined,
                color: Colors.redAccent, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasResume ? 'Resume uploaded' : 'Professional Resume',
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.pureWhite),
                ),
                Text(
                  hasResume ? 'Last updated: Recent' : 'Upload your PDF resume',
                  style: GoogleFonts.roboto(
                      fontSize: 13, color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _pickAndUploadResume(context),
            icon: Icon(
                hasResume ? Icons.refresh_rounded : Icons.file_upload_outlined,
                color: AppPalette.pureWhite,
                size: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadResume(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await UserService().uploadResume(uid, file);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resume uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildExpertiseCard(UserModel user) {
    final domains = user.domains;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Role',
            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            user.role,
            style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.pureWhite),
          ),
          const SizedBox(height: 20),
          Text(
            'Preferred Domains',
            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: domains.map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppPalette.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.border),
              ),
              child: Text(
                d,
                style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.pureWhite),
              ),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () => logout(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF331111)),
          backgroundColor: const Color(0xFF1A0505),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Logout from Session',
          style: GoogleFonts.roboto(color: Colors.redAccent, fontWeight: FontWeight.w600),
        ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppPalette.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('Profile not found', style: GoogleFonts.inter(color: AppPalette.textPrimary)),
          TextButton(onPressed: () => logout(context), child: const Text('Back to Login')),
        ],
      ),
    );
  }
}
