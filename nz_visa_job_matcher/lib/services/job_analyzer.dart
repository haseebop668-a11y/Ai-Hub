import '../models/job_record.dart';

class JobAnalysis {
  const JobAnalysis({
    required this.localOnly,
    required this.conflictingEvidence,
    required this.blockers,
    required this.signals,
    required this.matchedSkills,
    required this.matchScore,
    required this.category,
  });

  final bool localOnly;
  final bool conflictingEvidence;
  final List<String> blockers;
  final List<String> signals;
  final List<String> matchedSkills;
  final int matchScore;
  final String category;

  bool get hasSponsorSignal => signals.isNotEmpty;

  String get label {
    if (conflictingEvidence) return 'Conflicting wording — review';
    if (localOnly) return 'Likely local-only restriction';
    if (hasSponsorSignal) return 'Potential AEWV lead — not verified';
    return 'Sponsorship status unknown';
  }
}

class JobAnalyzer {
  static const blockerPhrases = <String>[
    'must have nz residency',
    'must have new zealand residency',
    'must already have nz work rights',
    'must have existing nz work rights',
    'must already hold a valid nz work visa',
    'valid nz work visa required',
    'nz citizens only',
    'new zealand citizens only',
    'permanent residents only',
    'right to work in nz essential',
    'right to work in new zealand essential',
    'no visa sponsorship',
    'sponsorship is not available',
    'not able to sponsor',
    'cannot provide visa sponsorship',
    'not open to overseas applicants',
    'overseas applicants are not accepted',
  ];

  static const sponsorPhrases = <String>[
    'aewv candidates welcome',
    'visa sponsorship available',
    'visa sponsorship',
    'overseas applicants welcome',
    'international applicants welcome',
    'relocation support',
    'visa support',
    'accredited employer work visa',
    'accredited employer',
  ];

  static String categoryFor(String description, String title) {
    final text = '$title $description'.toLowerCase();
    if (['warehouse', 'forklift', 'picker', 'dispatch', 'logistics', 'storeperson']
        .any(text.contains)) {
      return 'Warehousing & Logistics';
    }
    if (['painter', 'painting', 'surface preparation', 'coating', 'decorating']
        .any(text.contains)) {
      return 'Trades & Painting';
    }
    if (['civil', 'roading', 'roadwork', 'concrete', 'earthworks', 'drainage']
        .any(text.contains)) {
      return 'Works & Civil';
    }
    if (['construction', 'building site', 'scaffolding', 'hammer hand', 'site preparation']
        .any(text.contains)) {
      return 'Construction';
    }
    if (['maintenance', 'cleaning', 'general labour', 'general labor']
        .any(text.contains)) {
      return 'Maintenance & General Labour';
    }
    return 'General Labour';
  }

  static JobAnalysis analyze({
    required JobRecord job,
    required List<String> profileSkills,
  }) {
    final text = job.description.toLowerCase();
    final blockers = blockerPhrases.where((phrase) => text.contains(phrase)).toList();
    final explicitNoSponsor = const [
      'no visa sponsorship',
      'no sponsorship available',
      'sponsorship is not available',
      'not able to sponsor',
      'cannot provide visa sponsorship',
    ].any((phrase) => text.contains(phrase));
    final signals = sponsorPhrases.where((phrase) {
      if (explicitNoSponsor && phrase.contains('sponsorship')) return false;
      return text.contains(phrase);
    }).toList();
    final conflict = blockers.isNotEmpty && signals.isNotEmpty;
    final matched = profileSkills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty && text.contains(skill.toLowerCase()))
        .toSet()
        .toList();
    final uniqueSkills = profileSkills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toSet();
    final score = uniqueSkills.isEmpty
        ? 0
        : ((matched.length / uniqueSkills.length) * 100).round();

    return JobAnalysis(
      localOnly: blockers.isNotEmpty && !conflict,
      conflictingEvidence: conflict,
      blockers: blockers,
      signals: signals,
      matchedSkills: matched,
      matchScore: score.clamp(0, 100).toInt(),
      category: categoryFor(job.description, job.title),
    );
  }
}
