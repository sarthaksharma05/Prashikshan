class CompanyOnboardingData {
  CompanyOnboardingData({
    this.companyName = '',
    this.companyEmail = '',
    this.companySize = 'Startup',
    this.industryDomains = const <String>[],
    this.hiringType = 'Internship',
    this.location = '',
    this.websiteUrl = '',
  });

  final String companyName;
  final String companyEmail;
  final String companySize;
  final List<String> industryDomains;
  // hiringRoles REMOVED — will be collected per job posting instead
  final String hiringType;
  final String location;
  final String websiteUrl;

  CompanyOnboardingData copyWith({
    String? companyName,
    String? companyEmail,
    String? companySize,
    List<String>? industryDomains,
    String? hiringType,
    String? location,
    String? websiteUrl,
  }) {
    return CompanyOnboardingData(
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companySize: companySize ?? this.companySize,
      industryDomains: industryDomains ?? this.industryDomains,
      hiringType: hiringType ?? this.hiringType,
      location: location ?? this.location,
      websiteUrl: websiteUrl ?? this.websiteUrl,
    );
  }

  bool get isStep1Valid => companyName.isNotEmpty && companyEmail.isNotEmpty;
  // isStep2Valid: only requires at least one domain selected (no roles)
  bool get isStep2Valid => industryDomains.isNotEmpty;
  bool get isStep3Valid => location.isNotEmpty;
}
