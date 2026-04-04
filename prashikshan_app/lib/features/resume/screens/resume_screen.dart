import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/theme/app_palette.dart';
import '../../../services/api_service.dart';
import '../models/analysis_result.dart';
import 'analysis_result_screen.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  PlatformFile? _jdFile;
  PlatformFile? _resumeFile;
  bool _isLoading = false;

  Future<void> _pickFile(bool isJD) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );

    if (result != null) {
      setState(() {
        if (isJD) {
          _jdFile = result.files.first;
        } else {
          _resumeFile = result.files.first;
        }
      });
    }
  }

  Future<String> _extractText(PlatformFile file) async {
    try {
      final File pdfFile = File(file.path!);
      final List<int> bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return 'Error extracting text: $e';
    }
  }

  Future<void> _runAnalysis() async {
    if (_jdFile == null || _resumeFile == null) return;

    setState(() => _isLoading = true);

    try {
      final jdText = await _extractText(_jdFile!);

      if (jdText.contains('Error')) {
        throw Exception('File processing failed. Ensure files are valid PDFs.');
      }

      final result = await ApiService.analyzeResumeMatch(
        resumeFile: _resumeFile!,
        jdText: jdText,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[900],
            content: Text(
              'Analysis failed. Please check your internet or PDF format.',
              style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI SAFETY: Always return Scaffold first
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Match Audit',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('01. TARGET CONTEXT'),
                const SizedBox(height: 16),
                _buildUploadCard(
                  file: _jdFile,
                  label: 'UPLOAD JOB DESCRIPTION (PDF)',
                  onTap: () => _pickFile(true),
                ),
                const SizedBox(height: 48),
                _buildSectionHeader('02. PERSONAL DOSSIER'),
                const SizedBox(height: 16),
                _buildUploadCard(
                  file: _resumeFile,
                  label: 'UPLOAD RESUME (PDF/DOCX)',
                  onTap: () => _pickFile(false),
                ),
                const SizedBox(height: 60),
                _buildActionButton(),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'PERFORMING AI AUDIT...',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
               .fadeIn(duration: 800.ms)
               .then()
               .fadeOut(duration: 800.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildUploadCard({
    required PlatformFile? file,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? Colors.white : const Color(0xFF1A1A1A),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
              color: hasFile ? Colors.white : Colors.grey[800],
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              hasFile ? file.name.toUpperCase() : label,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: hasFile ? Colors.white : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildActionButton() {
    final bool canAnalyze = _jdFile != null && _resumeFile != null && !_isLoading;
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: canAnalyze ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: canAnalyze ? null : Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: InkWell(
        onTap: canAnalyze ? _runAnalysis : null,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            'RUN COMPATIBILITY AUDIT',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: canAnalyze ? Colors.black : Colors.grey[800],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 500.ms);
  }
}
