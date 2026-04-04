import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../onboarding/services/user_service.dart';
import '../../../core/theme/app_palette.dart';

class AddProjectScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String uid;

  const AddProjectScreen({
    super.key,
    required this.initialData,
    required this.uid,
  });

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentProjects =
          List<Map<String, dynamic>>.from(widget.initialData['projects'] ?? []);

      currentProjects.add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'github_link': _linkController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      await UserService().updateUserProfile(
        uid: widget.uid,
        updates: {'projects': currentProjects},
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
          'Add Project',
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
              onPressed: _addProject,
              child: Text(
                'ADD',
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
            _buildField('Project Title', _titleController, 'e.g. Portfolio App',
                Icons.folder_outlined),
            const SizedBox(height: 24),
            _buildField(
              'Description',
              _descController,
              'Describe your work...',
              Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildField('GitHub Repository Link', _linkController,
                'https://github.com/user/project', Icons.link_rounded),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      String hint, IconData icon,
      {int maxLines = 1}) {
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
          maxLines: maxLines,
          style: GoogleFonts.roboto(color: AppPalette.pureWhite),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppPalette.textMuted, size: 20),
            hintText: hint,
            hintStyle:
                GoogleFonts.roboto(color: AppPalette.textMuted, fontSize: 13),
            filled: true,
            fillColor: AppPalette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}
