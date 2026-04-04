import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_palette.dart';
import '../../../constants/domains.dart';

class PostHackathonForm extends StatefulWidget {
  final String uid;
  final ScrollController scrollController;

  const PostHackathonForm({super.key, required this.uid, required this.scrollController});

  @override
  State<PostHackathonForm> createState() => _PostHackathonFormState();
}

class _PostHackathonFormState extends State<PostHackathonForm> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _prizeController = TextEditingController();
  final _teamSizeController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _regLinkController = TextEditingController();

  String? _selectedDomain;
  String? _selectedMode;
  bool _isLoading = false;

  final List<String> _modes = ['Online', 'Offline', 'Hybrid'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppPalette.pureWhite,
              onPrimary: AppPalette.background,
              surface: AppPalette.surface,
              onSurface: AppPalette.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitHackathon() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Mode.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      final companyName = doc.data()?['companyName'] ?? doc.data()?['name'] ?? 'Company';

      await FirebaseFirestore.instance.collection('hackathons').add({
        'title': _titleController.text.trim(),
        'company': companyName,
        'domain': _selectedDomain,
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'mode': _selectedMode,
        'prize': _prizeController.text.trim(),
        'team_size': _teamSizeController.text.trim(),
        'deadline': _deadlineController.text.trim(),
        'registration_link': _regLinkController.text.trim(),
        'id': DateTime.now().millisecondsSinceEpoch,
        'posted_by_uid': widget.uid,
        'posted_by_company': companyName,
        'posted_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hackathon posted! Students will see it in their feed.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting hackathon: $e')),
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
          _buildFieldLabel('Hackathon Title'),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. AI Innovation Challenge'),
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

          _buildFieldLabel('Description'),
          TextFormField(
            controller: _descController,
            style: const TextStyle(color: AppPalette.pureWhite),
            maxLines: 3,
            decoration: _inputDecoration('Describe the hackathon theme and problem statement'),
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Location / Platform'),
          TextFormField(
            controller: _locationController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. Bangalore or Devfolio'),
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Mode'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modes.map((m) => ChoiceChip(
              label: Text(m, style: TextStyle(color: _selectedMode == m ? AppPalette.background : AppPalette.pureWhite)),
              selected: _selectedMode == m,
              selectedColor: AppPalette.pureWhite,
              backgroundColor: AppPalette.surface,
              onSelected: (val) {
                if (val) setState(() => _selectedMode = m);
              },
            )).toList(),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Prize'),
          TextFormField(
            controller: _prizeController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. ₹1,00,000').copyWith(
              prefixIcon: const Icon(Icons.emoji_events, color: AppPalette.textSecondary),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Team Size (Optional)'),
          TextFormField(
            controller: _teamSizeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('e.g. 2–4 members'),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Registration Deadline'),
          TextFormField(
            controller: _deadlineController,
            readOnly: true,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('YYYY-MM-DD').copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, color: AppPalette.textSecondary),
                onPressed: _pickDate,
              ),
            ),
            onTap: _pickDate,
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Registration Link'),
          TextFormField(
            controller: _regLinkController,
            style: const TextStyle(color: AppPalette.pureWhite),
            decoration: _inputDecoration('https://...'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required field';
              if (!v.startsWith('http')) return 'Must start with http or https';
              return null;
            },
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitHackathon,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.pureWhite,
                foregroundColor: AppPalette.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppPalette.pureWhite)
                  : Text('Post Hackathon', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
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
