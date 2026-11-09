enum ApplicationStage { saved, prepared, applied, shortlisted, closed }

extension ApplicationStageLabel on ApplicationStage {
  String get label {
    switch (this) {
      case ApplicationStage.saved:
        return 'Saved';
      case ApplicationStage.prepared:
        return 'Prepared';
      case ApplicationStage.applied:
        return 'Applied';
      case ApplicationStage.shortlisted:
        return 'Shortlisted';
      case ApplicationStage.closed:
        return 'Closed';
    }
  }
}

class JobRecord {
  const JobRecord({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.source,
    required this.url,
    required this.createdAt,
    this.stage = ApplicationStage.saved,
    this.paused = false,
    this.employerAccredited = false,
    this.jobCheckConfirmed = false,
    this.hoursPerWeek = 0,
    this.verificationEvidence = '',
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String source;
  final String url;
  final DateTime createdAt;
  final ApplicationStage stage;
  final bool paused;
  final bool employerAccredited;
  final bool jobCheckConfirmed;
  final int hoursPerWeek;
  final String verificationEvidence;

  bool get evidenceChecklistComplete =>
      employerAccredited &&
      jobCheckConfirmed &&
      hoursPerWeek >= 30 &&
      verificationEvidence.trim().isNotEmpty;

  factory JobRecord.fromJson(Map<String, dynamic> json) {
    final stageName = json['stage'] as String? ?? 'saved';
    final stage = ApplicationStage.values.firstWhere(
      (item) => item.name == stageName,
      orElse: () => ApplicationStage.saved,
    );
    return JobRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? 'Manual import',
      url: json['url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      stage: stage,
      paused: json['paused'] as bool? ?? false,
      employerAccredited: json['employerAccredited'] as bool? ?? false,
      jobCheckConfirmed: json['jobCheckConfirmed'] as bool? ?? false,
      hoursPerWeek: json['hoursPerWeek'] as int? ?? 0,
      verificationEvidence: json['verificationEvidence'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'location': location,
        'description': description,
        'source': source,
        'url': url,
        'createdAt': createdAt.toIso8601String(),
        'stage': stage.name,
        'paused': paused,
        'employerAccredited': employerAccredited,
        'jobCheckConfirmed': jobCheckConfirmed,
        'hoursPerWeek': hoursPerWeek,
        'verificationEvidence': verificationEvidence,
      };

  JobRecord copyWith({
    ApplicationStage? stage,
    bool? paused,
    bool? employerAccredited,
    bool? jobCheckConfirmed,
    int? hoursPerWeek,
    String? verificationEvidence,
  }) {
    return JobRecord(
      id: id,
      title: title,
      company: company,
      location: location,
      description: description,
      source: source,
      url: url,
      createdAt: createdAt,
      stage: stage ?? this.stage,
      paused: paused ?? this.paused,
      employerAccredited: employerAccredited ?? this.employerAccredited,
      jobCheckConfirmed: jobCheckConfirmed ?? this.jobCheckConfirmed,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      verificationEvidence: verificationEvidence ?? this.verificationEvidence,
    );
  }
}
