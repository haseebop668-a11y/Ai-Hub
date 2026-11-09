import 'package:flutter_test/flutter_test.dart';
import 'package:nz_visa_job_matcher/models/job_record.dart';
import 'package:nz_visa_job_matcher/services/job_analyzer.dart';

JobRecord job(String description) => JobRecord(
      id: '1',
      title: 'General Labourer',
      company: 'Example Employer',
      location: 'Auckland',
      description: description,
      source: 'Test',
      url: '',
      createdAt: DateTime(2026, 11, 9),
    );

void main() {
  group('JobAnalyzer', () {
    test('flags explicit local-only work-right restrictions', () {
      final result = JobAnalyzer.analyze(
        job: job('Must have NZ residency. No visa sponsorship.'),
        profileSkills: const ['warehouse picking'],
      );
      expect(result.localOnly, isTrue);
      expect(result.label, contains('local-only'));
    });

    test('treats conflicting positive and negative wording as review', () {
      final result = JobAnalyzer.analyze(
        job: job('Visa sponsorship available, but valid NZ work visa required.'),
        profileSkills: const [],
      );
      expect(result.conflictingEvidence, isTrue);
      expect(result.localOnly, isFalse);
    });

    test('positive sponsorship wording is only a potential lead', () {
      final result = JobAnalyzer.analyze(
        job: job('AEWV candidates welcome. Overseas applicants may apply.'),
        profileSkills: const ['forklift operation'],
      );
      expect(result.hasSponsorSignal, isTrue);
      expect(result.label, contains('not verified'));
    });

    test('does not invent skill matches when the profile is empty', () {
      final result = JobAnalyzer.analyze(
        job: job('Concrete mixing and site preparation required.'),
        profileSkills: const [],
      );
      expect(result.matchScore, 0);
      expect(result.matchedSkills, isEmpty);
    });

    test('calculates overlap from user supplied skills only', () {
      final result = JobAnalyzer.analyze(
        job: job('Warehouse picking, packing and stock dispatch.'),
        profileSkills: const ['warehouse picking', 'forklift licence'],
      );
      expect(result.matchedSkills, ['warehouse picking']);
      expect(result.matchScore, 50);
    });

    test('classifies warehouse and civil roles without inventing experience', () {
      expect(JobAnalyzer.categoryFor('Forklift and stock dispatch', 'Storeperson'),
          'Warehousing & Logistics');
      expect(JobAnalyzer.categoryFor('Concrete and roading works', 'Civil Labourer'),
          'Works & Civil');
    });
  });
}
