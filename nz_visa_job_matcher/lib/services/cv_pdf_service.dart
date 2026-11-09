import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/job_record.dart';
import '../models/user_profile.dart';
import 'job_analyzer.dart';

class CvPdfService {
  static Future<Uint8List> buildPdf(UserProfile profile, JobRecord job) async {
    final document = pw.Document();
    pw.MemoryImage? photo;
    final photoPath = profile.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final file = File(photoPath);
        if (await file.exists()) photo = pw.MemoryImage(await file.readAsBytes());
      } on FileSystemException {
        photo = null;
      }
    }

    final analysis = JobAnalyzer.analyze(job: job, profileSkills: profile.skills);
    final selectedSkills = analysis.matchedSkills.isNotEmpty
        ? analysis.matchedSkills
        : profile.skills;
    final skillsText = selectedSkills.isEmpty
        ? 'No verified skills have been added yet.'
        : selectedSkills.join('  •  ');

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile.name.isEmpty ? 'Applicant name required' : profile.name,
                        style: pw.TextStyle(
                          fontSize: 23,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1E293B'),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        [profile.email, profile.phone, profile.location]
                            .where((value) => value.trim().isNotEmpty)
                            .join('  |  '),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '${analysis.category.toUpperCase()}  •  ${job.title}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#D97706'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (photo != null)
                  pw.Container(width: 68, height: 82, child: pw.Image(photo, fit: pw.BoxFit.cover)),
              ],
            ),
            pw.SizedBox(height: 17),
            _section('PROFESSIONAL SUMMARY', profile.summary),
            _section('RELEVANT VERIFIED SKILLS', skillsText),
            _section('EMPLOYMENT EXPERIENCE', profile.experience),
            _section('QUALIFICATIONS & TRAINING', profile.qualifications),
            pw.Spacer(),
            pw.Divider(color: PdfColor.fromHex('#D97706')),
            pw.Text('Prepared for ${job.company} • ${job.location}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(
              'Keyword overlap: ${analysis.matchScore}% of the skills entered in this profile. This is not an ATS pass guarantee.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );

    final coverLetter = _coverLetter(profile, job, analysis);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('COVER LETTER',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#D97706'),
                  letterSpacing: 1.2,
                )),
            pw.SizedBox(height: 12),
            pw.Text('Application: ${job.title}',
                style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
            pw.Text('${job.company} • ${job.location}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 25),
            ...coverLetter.split('\n\n').map((paragraph) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 13),
                  child: pw.Text(paragraph, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 4)),
                )),
            pw.Spacer(),
            pw.Divider(color: PdfColor.fromHex('#D97706')),
            pw.Text(profile.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(profile.email, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );
    return document.save();
  }

  static pw.Widget _section(String title, String value) {
    if (value.trim().isEmpty) return pw.SizedBox(height: 3);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 13),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
          pw.SizedBox(height: 5),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 3)),
        ],
      ),
    );
  }

  static String _coverLetter(UserProfile profile, JobRecord job, JobAnalysis analysis) {
    final skills = analysis.matchedSkills.isEmpty
        ? 'the skills and experience described in my attached profile'
        : analysis.matchedSkills.join(', ');
    final background = profile.summary.trim().isEmpty
        ? 'I would welcome the opportunity to discuss my relevant background and provide supporting evidence.'
        : profile.summary.trim();
    return 'Dear Hiring Manager,\n\n'
        'I am writing to apply for the ${job.title} opportunity with ${job.company} in ${job.location}.\n\n'
        '$background\n\n'
        'The experience and capabilities I have listed that are relevant to this vacancy include: $skills. '
        'I have included only information supplied in my candidate profile and can discuss supporting documents during the recruitment process.\n\n'
        'I am currently based in ${profile.location}. I would require an employer-supported work visa pathway. '
        'Please confirm whether this specific vacancy is open to applicants outside New Zealand, whether the employing entity currently holds the relevant accreditation, '
        'and whether an approved job check is in place for this role.\n\n'
        'Thank you for considering my application. I would appreciate the opportunity to discuss the role and its requirements.\n\n'
        'Yours sincerely,\n${profile.name}';
  }

  static Future<void> preview(UserProfile profile, JobRecord job) async {
    final bytes = await buildPdf(profile, job);
    await Printing.layoutPdf(
      name: 'NZ-Application-${job.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.pdf',
      onLayout: (format) async => bytes,
    );
  }
}
