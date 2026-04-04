import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../onboarding/services/user_service.dart';
import '../../../core/theme/app_palette.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String uid;

  const EditProfileScreen({
    super.key,
    required this.initialData,
    required this.uid,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _universityController;
  late TextEditingController _cgpaController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _universityController =
        TextEditingController(text: widget.initialData['university']);
    _cgpaController = TextEditingController(text: widget.initialData['cgpa']);
    _githubController =
        TextEditingController(text: widget.initialData['githubUrl']);
    _linkedinController =
        TextEditingController(text: widget.initialData['linkedinUrl']);
    _phoneController =
        TextEditingController(text: widget.initialData['mobileNumber']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _cgpaController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Update Firestore profile
      await UserService().updateUserProfile(
        uid: widget.uid,
        updates: {
          'name': _nameController.text.trim(),
          'university': _universityController.text.trim(),
          'cgpa': _cgpaController.text.trim(),
          'githubUrl': _githubController.text.trim(),
          'linkedinUrl': _linkedinController.text.trim(),
          'mobileNumber': _phoneController.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w700,
            color: AppPalette.pureWhite,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppPalette.pureWhite),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'SAVE',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w900,
                  color: AppPalette.pureWhite,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            _buildField('Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 20),
            _buildField('Mobile Number', _phoneController, Icons.phone_android_outlined),
            const SizedBox(height: 20),
            _buildField('University', _universityController, Icons.school_outlined),
            const SizedBox(height: 20),
            _buildField('CGPA', _cgpaController, Icons.analytics_outlined),
            const SizedBox(height: 32),
            Text(
              'PROFESSIONAL LINKS',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            _buildField('GitHub URL', _githubController, Icons.code_rounded),
            const SizedBox(height: 20),
            _buildField('LinkedIn URL', _linkedinController, Icons.link_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.roboto(color: AppPalette.pureWhite),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppPalette.textMuted, size: 20),
            filled: true,
            fillColor: AppPalette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppPalette.pureWhite.withOpacity(0.05)),
            ),
          ),
        ),
      ],
    );
  }
}
