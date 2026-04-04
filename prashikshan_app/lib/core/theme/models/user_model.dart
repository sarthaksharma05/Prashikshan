/// User model representing user profile in Firestore
class UserModel {
  /// User's full name
  final String name;

  /// User's email
  final String email;

  /// User's role (Student, University, Company)
  final String role;

  /// List of interested domains
  final List<String> domains;

  /// Experience level (Beginner, Intermediate, Advanced)
  final String level;

  /// Looking for (Internships, Jobs, Projects)
  final String lookingFor;

  /// Whether user has completed onboarding
  final bool isOnboarded;

  /// Timestamp when user was created
  final dynamic createdAt;

  /// GitHub profile link
  final String? githubUrl;

  /// LinkedIn profile link
  final String? linkedinUrl;

  /// Resume PDF download URL
  final String? resumeUrl;

  /// User's academic/professional projects
  final List<Map<String, dynamic>> projects;

  /// User's mobile phone number
  final String? mobileNumber;

  /// User's profile photo download URL
  final String? profilePhotoUrl;

  /// User's university
  final String? university;

  /// User's CGPA
  final String? cgpa;

  /// Constructor
  UserModel({
    required this.name,
    required this.email,
    required this.role,
    required this.domains,
    required this.level,
    required this.lookingFor,
    this.isOnboarded = true,
    this.createdAt,
    this.githubUrl,
    this.linkedinUrl,
    this.resumeUrl,
    this.projects = const [],
    this.mobileNumber,
    this.profilePhotoUrl,
    this.university,
    this.cgpa,
  });

  /// Convert UserModel to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'role': role,
      'domains': domains,
      'level': level,
      'lookingFor': lookingFor,
      'isOnboarded': isOnboarded,
      'createdAt': createdAt,
      'githubUrl': githubUrl,
      'linkedinUrl': linkedinUrl,
      'resumeUrl': resumeUrl,
      'projects': projects,
      'mobileNumber': mobileNumber,
      'profilePhotoUrl': profilePhotoUrl,
      'university': university,
      'cgpa': cgpa,
    };
  }

  /// Factory constructor to create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'Student',
      domains: List<String>.from(data['domains'] as List<dynamic>? ?? []),
      level: data['level'] as String? ?? 'Beginner',
      lookingFor: data['lookingFor'] as String? ?? 'Internships',
      isOnboarded: data['isOnboarded'] as bool? ?? false,
      createdAt: data['createdAt'],
      githubUrl: data['githubUrl'] as String?,
      linkedinUrl: data['linkedinUrl'] as String?,
      resumeUrl: data['resumeUrl'] as String?,
      mobileNumber: data['mobileNumber'] as String?,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      university: data['university'] as String?,
      cgpa: data['cgpa'] as String?,
      projects: List<Map<String, dynamic>>.from(
        data['projects'] as List<dynamic>? ?? [],
      ),
    );
  }
}
