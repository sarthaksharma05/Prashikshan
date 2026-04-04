class OnboardingData {
  OnboardingData({
    this.fullName = '',
    this.email = '',
    this.mobileNumber = '',
    this.university = '',
    this.cgpa = '',
    this.role = 'student', // ✅ FIXED: lowercase to match AppRouter comparison
    this.selectedDomains = const <String>[],
    this.level = 'Beginner',
    this.lookingFor = 'Internships',
  });

  final String fullName;
  final String email;
  final String mobileNumber;
  final String university;
  final String cgpa;
  final String role;
  final List<String> selectedDomains;
  final String level;
  final String lookingFor;

  OnboardingData copyWith({
    String? fullName,
    String? email,
    String? mobileNumber,
    String? university,
    String? cgpa,
    String? role,
    List<String>? selectedDomains,
    String? level,
    String? lookingFor,
  }) {
    return OnboardingData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      university: university ?? this.university,
      cgpa: cgpa ?? this.cgpa,
      role: role ?? this.role,
      selectedDomains: selectedDomains ?? this.selectedDomains,
      level: level ?? this.level,
      lookingFor: lookingFor ?? this.lookingFor,
    );
  }

  bool get isStep1Valid => fullName.isNotEmpty && email.isNotEmpty;
  bool get isStep2Valid => selectedDomains.isNotEmpty;
  bool get isStep3Valid =>
      university.isNotEmpty && mobileNumber.length >= 10 && cgpa.isNotEmpty;
}
