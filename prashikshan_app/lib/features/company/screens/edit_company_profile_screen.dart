import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;
  final String uid;

  const EditCompanyProfileScreen({
    super.key,
    required this.companyData,
    required this.uid,
  });

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _cityController;
  late TextEditingController _websiteController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;

  List<String> _hiringDomains = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.companyData;

    _nameController = TextEditingController(
      text: d['company_name'] ?? d['companyName'] ?? d['name'] ?? '',
    );
    _sizeController = TextEditingController(
      text: d['company_size'] ?? d['companySize'] ?? '',
    );
    _cityController = TextEditingController(
      text: d['city'] ?? d['location'] ?? '',
    );
    _websiteController = TextEditingController(
      text: d['website'] ?? d['websiteUrl'] ?? '',
    );
    _contactPersonController = TextEditingController(
      text: d['contactPerson'] ?? d['name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: d['phone'] ?? d['mobileNumber'] ?? '',
    );

    _hiringDomains = List<String>.from(d['hiringDomains'] ?? d['domains'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'company_name': _nameController.text.trim(),
        'companyName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'company_size': _sizeController.text.trim(),
        'city': _cityController.text.trim(),
        'location': _cityController.text.trim(),
        'website': _websiteController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hiringDomains': _hiringDomains,
        'domains': _hiringDomains,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context); // Go back to profile tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppPalette.pureWhite),
        title: Text('Edit Profile',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppPalette.pureWhite)),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppPalette.pureWhite))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Company Information'),
                    _buildTextField(_nameController, 'Company Name', Icons.business),
                    _buildTextField(_sizeController, 'Company Size', Icons.people_alt_outlined),
                    _buildTextField(_cityController, 'City', Icons.location_on_outlined),
                    _buildTextField(_websiteController, 'Website', Icons.language),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Contact Details'),
                    _buildTextField(_contactPersonController, 'Contact Person', Icons.person_outline),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, isPhone: true),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Hiring Preferences (Domains)'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kDomains.map((domainData) {
                        final String label = domainData['label'];
                        final isSelected = _hiringDomains.contains(label);
                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _hiringDomains.add(label);
                              } else {
                                _hiringDomains.remove(label);
                              }
                            });
                          },
                          backgroundColor: AppPalette.surface,
                          selectedColor: Colors.blue.shade900,
                          checkmarkColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppPalette.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? Colors.blue.shade800 : AppPalette.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppPalette.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: GoogleFonts.inter(color: AppPalette.pureWhite),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppPalette.textMuted),
          prefixIcon: Icon(icon, color: AppPalette.textSecondary, size: 20),
          filled: true,
          fillColor: AppPalette.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.pureWhite),
          ),
        ),
      ),
    );
  }
}
