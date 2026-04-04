class Hackathon {
  final int id;
  final String title;
  final String company;
  final String location;
  final String mode;
  final String prize;
  final String deadline;
  final String description;
  final String domain;
  final String registrationLink;
  final String teamSize;

  Hackathon({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.mode,
    required this.prize,
    required this.deadline,
    required this.description,
    required this.domain,
    required this.registrationLink,
    this.teamSize = '',
  });

  factory Hackathon.fromMap(Map<String, dynamic> map) {
    return Hackathon(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      mode: map['mode'] ?? 'Online',
      prize: map['prize'] ?? 'N/A',
      deadline: map['deadline'] ?? '',
      description: map['description'] ?? '',
      domain: map['domain'] ?? '',
      registrationLink: map['registration_link'] ?? '',
      teamSize: map['team_size']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'mode': mode,
      'prize': prize,
      'deadline': deadline,
      'description': description,
      'domain': domain,
      'registration_link': registrationLink,
    };
  }
}
