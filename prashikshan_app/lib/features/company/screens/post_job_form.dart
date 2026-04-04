import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../../../constants/domains.dart';

class PostJobForm extends StatefulWidget {
  final String uid;
  final ScrollController scrollController;

  const PostJobForm({super.key, required this.uid, required this.scrollController});

  @override
  State<PostJobForm> createState() => _PostJobFormState();
}

class _PostJobFormState extends State<PostJobForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillInputController = TextEditingController();

  String? _selectedDomain;
  final List<String> _skills = [];
  String? _selectedType;
  String? _selectedExpLevel;
  bool _isLoading = false;

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Internship', 'Contract'];
  final List<String> _expLevels = ['Fresher', '0–1 yr', '1–3 yrs', '3+ yrs'];

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() => _skills.add(skill));
      _skillInputController.clear();
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 skill.')),
      );
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Job Type.')),
      );
      return;
    }
    if (_selectedExpLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Experience Level.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch company name
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      final companyName = doc.data()?['companyName'] ?? doc.data()?['name'] ?? 'Company';

      await FirebaseFirestore.instance.collection('jobs').add({
        'title': _titleController.text.trim(),
        'company': companyName,
        'domain': _selectedDomain,
        'location': _locationController.text.trim(),
        'skills': _skills,
        'type': _selectedType,
        'experience_level': _selectedExpLevel,
        'salary': _salaryController.text.trim(),
        'job_id': DateTime.now().millisecondsSinceEpoch,
        'posted_by_uid': widget.uid,
        'posted_by_company': companyName,
        'posted_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully! Students will see it in their feed.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          _buildFieldLabel('Job Title'),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. Flutter Developer Intern'),
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Domain'),
          DropdownButtonFormField<String>(
            value: _selectedDomain,
            dropdownColor: AppPalette.surface,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('Select a domain'),
            items: kDomains.map((d) {
              return DropdownMenuItem<String>(
                value: d['label'] as String,
                child: Text(d['label'] as String),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedDomain = val),
            validator: (v) => v == null ? 'Must select a domain' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Location'),
          TextFormField(
            controller: _locationController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. Bangalore, India'),
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Skills Required'),
          TextFormField(
            controller: _skillInputController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('Type a skill and tap add').copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: AppPalette.pureWhite),
                onPressed: _addSkill,
              ),
            ),
            onFieldSubmitted: (_) => _addSkill(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((s) => Chip(
              label: Text(s, style: const TextStyle(color: AppPalette.background)),
              backgroundColor: AppPalette.pureWhite,
              deleteIcon: const Icon(Icons.close, size: 16, color: AppPalette.background),
              onDeleted: () => _removeSkill(s),
            )).toList(),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Job Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _jobTypes.map((t) => ChoiceChip(
              label: Text(t, style: TextStyle(color: _selectedType == t ? AppPalette.background : AppPalette.pureWhite)),
              selected: _selectedType == t,
              selectedColor: AppPalette.pureWhite,
              backgroundColor: AppPalette.surface,
              onSelected: (val) {
                if (val) setState(() => _selectedType = t);
              },
            )).toList(),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Experience Level'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _expLevels.map((t) => ChoiceChip(
              label: Text(t, style: TextStyle(color: _selectedExpLevel == t ? AppPalette.background : AppPalette.pureWhite)),
              selected: _selectedExpLevel == t,
              selectedColor: AppPalette.pureWhite,
              backgroundColor: AppPalette.surface,
              onSelected: (val) {
                if (val) setState(() => _selectedExpLevel = t);
              },
            )).toList(),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Salary / Stipend (Optional)'),
          TextFormField(
            controller: _salaryController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. ₹15,000/month or Unpaid'),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.pureWhite,
                foregroundColor: AppPalette.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppPalette.pureWhite)
                  : Text('Post Job', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          color: AppPalette.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppPalette.textMuted),
      filled: true,
      fillColor: AppPalette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.pureWhite),
      ),
    );
  }
}
