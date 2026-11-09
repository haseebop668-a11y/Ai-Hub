class UserProfile {
  const UserProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.location = 'Pakistan',
    this.summary = '',
    this.experience = '',
    this.qualifications = '',
    this.skills = const [],
    this.photoPath,
  });

  final String name;
  final String email;
  final String phone;
  final String location;
  final String summary;
  final String experience;
  final String qualifications;
  final List<String> skills;
  final String? photoPath;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? 'Pakistan',
      summary: json['summary'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      qualifications: json['qualifications'] as String? ?? '',
      skills: List<String>.from(json['skills'] as List? ?? const []),
      photoPath: json['photoPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'summary': summary,
        'experience': experience,
        'qualifications': qualifications,
        'skills': skills,
        'photoPath': photoPath,
      };

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? location,
    String? summary,
    String? experience,
    String? qualifications,
    List<String>? skills,
    String? photoPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      summary: summary ?? this.summary,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      skills: skills ?? this.skills,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
