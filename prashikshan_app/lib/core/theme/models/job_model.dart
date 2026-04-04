/// Job model representing a job listing from Firestore
class Job {
  /// Job title (e.g., 'Senior Flutter Developer')
  final String title;

  /// Company name
  final String company;

  /// Job location
  final String location;

  /// Job description
  final String description;

  /// Required skills list
  final List<dynamic> skills;

  /// Domain/category (e.g., 'Mobile Development', 'Web')
  final String domain;

  /// Constructor
  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.skills,
    required this.domain,
  });

  /// Factory constructor to create Job from Firestore document
  factory Job.fromFirestore(Map<String, dynamic> data) {
    return Job(
      title: data['title'] as String? ?? '',
      company: data['company'] as String? ?? '',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      skills: data['skills'] as List<dynamic>? ?? [],
      domain: data['domain'] as String? ?? '',
    );
  }

  /// Convert Job to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'skills': skills,
      'domain': domain,
    };
  }
}
