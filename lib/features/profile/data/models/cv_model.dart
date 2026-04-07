class Education {
  final String id;
  final String institution;
  final String degree;
  final String? fieldOfStudy;
  final String? startDate;
  final String? endDate;
  final String? description;

  Education({
    required this.id,
    required this.institution,
    required this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'],
      institution: json['institution'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      description: json['description'],
    );
  }
}

class WorkExperience {
  final String id;
  final String company;
  final String position;
  final String? location;
  final String? startDate;
  final String? endDate;
  final String? description;

  WorkExperience({
    required this.id,
    required this.company,
    required this.position,
    this.location,
    this.startDate,
    this.endDate,
    this.description,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'],
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      description: json['description'],
    );
  }
}

class Certification {
  final String id;
  final String name;
  final String issuingOrganization;
  final String? issueDate;
  final String? expirationDate;
  final String? credentialId;
  final String? credentialUrl;

  Certification({
    required this.id,
    required this.name,
    required this.issuingOrganization,
    this.issueDate,
    this.expirationDate,
    this.credentialId,
    this.credentialUrl,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'],
      name: json['name'] ?? '',
      issuingOrganization: json['issuingOrganization'] ?? '',
      issueDate: json['issueDate'],
      expirationDate: json['expirationDate'],
      credentialId: json['credentialId'],
      credentialUrl: json['credentialUrl'],
    );
  }
}

class ProfessionalSkill {
  final String id;
  final String name;
  final String? level;

  ProfessionalSkill({
    required this.id,
    required this.name,
    this.level,
  });

  factory ProfessionalSkill.fromJson(Map<String, dynamic> json) {
    return ProfessionalSkill(
      id: json['id'],
      name: json['name'] ?? '',
      level: json['level'],
    );
  }
}

class Publication {
  final String id;
  final String title;
  final String? publisher;
  final String? publicationDate;
  final String? url;
  final String? description;

  Publication({
    required this.id,
    required this.title,
    this.publisher,
    this.publicationDate,
    this.url,
    this.description,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'],
      title: json['title'] ?? '',
      publisher: json['publisher'],
      publicationDate: json['publicationDate'],
      url: json['url'],
      description: json['description'],
    );
  }
}

class CVData {
  final List<Education> education;
  final List<WorkExperience> experience;
  final List<Certification> certifications;
  final List<ProfessionalSkill> skills;
  final List<Publication> publications;

  CVData({
    this.education = const [],
    this.experience = const [],
    this.certifications = const [],
    this.skills = const [],
    this.publications = const [],
  });
}
