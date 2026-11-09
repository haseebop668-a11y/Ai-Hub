import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../models/job_record.dart';
import '../models/user_profile.dart';
import '../services/app_storage.dart';
import '../services/cv_pdf_service.dart';
import '../services/job_analyzer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppStorage _storage = AppStorage();
  UserProfile _profile = const UserProfile();
  List<JobRecord> _jobs = [];
  bool _loading = true;
  int _tab = 0;

  static const _sources = <Map<String, String>>[
    {
      'name': 'Trade Assist',
      'detail': 'Job listings and international AEWV recruitment',
      'url': 'https://tradeassist.net/job-listings',
    },
    {
      'name': 'Enterprise Recruitment',
      'detail': 'Official job search and candidate registration',
      'url': 'https://www.enterprise.co.nz/job-results',
    },
    {
      'name': 'Tradestaff',
      'detail': 'Construction, civil, trades and logistics vacancies',
      'url': 'https://www.tradestaff.co.nz/jobs/',
    },
    {
      'name': 'SEEK New Zealand',
      'detail': 'Open manually; automated scraping is not enabled',
      'url': 'https://nz.seek.com/search-jobs',
    },
    {
      'name': 'INZ accredited employer search',
      'detail': 'Check the legal employer name or 13-digit NZBN',
      'url': 'https://www.immigration.govt.nz/work/requirements-for-work-visas/approved-employers/accredited-employer-list/',
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        _storage.loadProfile(),
        _storage.loadJobs(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = values[0] as UserProfile;
        _jobs = values[1] as List<JobRecord>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile(UserProfile value) async {
    setState(() => _profile = value);
    await _storage.saveProfile(value);
  }

  Future<void> _saveJobs() => _storage.saveJobs(_jobs);

  Future<void> _updateJob(JobRecord updated) async {
    setState(() {
      _jobs = _jobs.map((job) => job.id == updated.id ? updated : job).toList();
    });
    await _saveJobs();
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      _message('This listing does not have a valid web link.');
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _message('Could not open the link. Try copying it into your browser.');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [_dashboard(), _jobsPage(), _profilePage(), _trackerPage()];
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NZ Visa Job Matcher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Overseas applicant workspace',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recruitment sources',
            onPressed: () => setState(() => _tab = 1),
            icon: const Icon(Icons.travel_explore),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Jobs'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
          NavigationDestination(
              icon: Icon(Icons.track_changes),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tracker'),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    final scannedToday = _jobs.where((job) =>
        job.createdAt.year == now.year &&
        job.createdAt.month == now.month &&
        job.createdAt.day == now.day).length;
    final sponsorSignals = _jobs.where((job) {
      final result = JobAnalyzer.analyze(job: job, profileSkills: _profile.skills);
      return result.hasSponsorSignal && !result.localOnly;
    }).length;
    final evidenceChecked =
        _jobs.where((job) => job.evidenceChecklistComplete).length;
    final submitted = _jobs
        .where((job) =>
            job.stage == ApplicationStage.applied ||
            job.stage == ApplicationStage.shortlisted)
        .length;
    final shortlisted =
        _jobs.where((job) => job.stage == ApplicationStage.shortlisted).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YOUR NEW ZEALAND SEARCH',
                  style: TextStyle(
                      color: Color(0xFFFFD18A),
                      fontSize: 10,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _profile.name.isEmpty
                    ? 'Build your candidate profile'
                    : 'Welcome, ${_profile.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find relevant vacancies, check the visa evidence, and prepare truthful applications.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _RegionPill('Auckland'),
                  _RegionPill('Christchurch'),
                  _RegionPill('Wellington'),
                  _RegionPill('Hawke’s Bay'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _MetricCard(
                label: 'Jobs imported today',
                value: '$scannedToday',
                icon: Icons.travel_explore,
                color: navy),
            _MetricCard(
                label: 'Sponsorship signals',
                value: '$sponsorSignals',
                icon: Icons.flag_outlined,
                color: amber),
            _MetricCard(
                label: 'Evidence checklist complete',
                value: '$evidenceChecked',
                icon: Icons.verified_outlined,
                color: const Color(0xFF0F766E)),
            _MetricCard(
                label: 'Applications submitted',
                value: '$submitted',
                icon: Icons.send_outlined,
                color: const Color(0xFF475569)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFFFFF3DE),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF9A5B00)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evidence checklist complete: $evidenceChecked. This is your recorded evidence check, not an Immigration New Zealand decision. Employer accreditation alone does not prove a job check for a specific vacancy.',
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF68420C)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_profile.skills.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_add_alt_1, color: amber),
              title: const Text('Add your real skills and work history'),
              subtitle: const Text(
                  'Your match score and CV use only details you enter.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _tab = 2),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent jobs',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: navy)),
            TextButton(
                onPressed: () => setState(() => _tab = 1),
                child: const Text('View all')),
          ],
        ),
        if (_jobs.isEmpty)
          const _EmptyCard(
            icon: Icons.work_history_outlined,
            title: 'No jobs imported yet',
            detail:
                'Open a recruitment source, review a vacancy, then add its details and description to the Jobs tab.',
          )
        else
          ..._jobs.take(3).map(_jobCard),
        const SizedBox(height: 8),
        Text('Shortlist / interview alerts: $shortlisted',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: navy)),
      ],
    );
  }

  Widget _jobsPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Job discovery',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: navy)),
            ),
            FilledButton.icon(
              onPressed: _showAddJob,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Import job'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Open these sites manually. Import only vacancies you have actually reviewed. The app does not scrape or crawl restricted portals.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 12),
        ..._sources.map((source) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF1D9),
                  child: Icon(Icons.open_in_new, color: amber),
                ),
                title: Text(source['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(source['detail']!,
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openUrl(source['url']!),
              ),
            )),
        const SizedBox(height: 8),
        const Text('Imported vacancies',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: navy)),
        if (_jobs.isEmpty)
          const _EmptyCard(
            icon: Icons.content_paste_search,
            title: 'Your job list is empty',
            detail:
                'Copy the vacancy details from a recruitment page and choose Import job.',
          )
        else
          ..._jobs.map(_jobCard),
      ],
    );
  }

  Widget _profilePage() {
    final photo = _profile.photoPath;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Candidate profile',
            style: TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFFFFF1D9),
                      backgroundImage: photo != null && File(photo).existsSync()
                          ? FileImage(File(photo))
                          : null,
                      child: photo == null
                          ? const Icon(Icons.person, size: 38, color: navy)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _profile.name.isEmpty
                                  ? 'Name not added'
                                  : _profile.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: navy)),
                          Text(
                              _profile.email.isEmpty
                                  ? 'Email not added'
                                  : _profile.email,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          Text(_profile.location,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit profile'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _profileSection('Professional summary', _profile.summary),
        _profileSection('Work experience', _profile.experience),
        _profileSection('Qualifications', _profile.qualifications),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Skills you can prove',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 8),
                if (_profile.skills.isEmpty)
                  const Text('No skills entered yet.',
                      style: TextStyle(color: Colors.black54))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _profile.skills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Only add skills, licences, machinery experience and lifting capacity that are genuinely yours and can be supported with evidence.',
                  style: TextStyle(
                      fontSize: 11, height: 1.4, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline, color: navy),
            title: Text('Private on this device'),
            subtitle: Text(
                'Your profile is stored in Android secure storage. It is not committed to GitHub or sent to an AI service.'),
          ),
        ),
      ],
    );
  }

  Widget _profileSection(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 5),
            Text(value.isEmpty ? 'Not added yet.' : value,
                style: TextStyle(
                    color: value.isEmpty ? Colors.black45 : Colors.black87,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _trackerPage() {
    final tracked = _jobs
        .where((job) => job.stage != ApplicationStage.saved || job.paused)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text('Application tracker',
            style: TextStyle(
                fontSize: 21, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 6),
        const Text('Update a job after you submit it yourself or receive a response.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        if (tracked.isEmpty)
          const _EmptyCard(
            icon: Icons.track_changes,
            title: 'Nothing in progress',
            detail:
                'Prepare an application, submit it on the original employer portal, then mark it as Applied.',
          )
        else
          ...tracked.map((job) => Card(
                child: ListTile(
                  title: Text(job.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${job.company} • ${job.stage.label}${job.paused ? ' • Paused' : ''}'),
                  trailing: PopupMenuButton<ApplicationStage>(
                    tooltip: 'Update status',
                    onSelected: (stage) =>
                        _updateJob(job.copyWith(stage: stage)),
                    itemBuilder: (context) => ApplicationStage.values
                        .map((stage) => PopupMenuItem(
                            value: stage, child: Text(stage.label)))
                        .toList(),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _jobCard(JobRecord job) {
    final analysis =
        JobAnalyzer.analyze(job: job, profileSkills: _profile.skills);
    final isBlocked = analysis.localOnly;
    final statusColor = analysis.conflictingEvidence
        ? const Color(0xFFB45309)
        : isBlocked
            ? const Color(0xFFB91C1C)
            : analysis.hasSponsorSignal
                ? const Color(0xFF9A5B00)
                : const Color(0xFF475569);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(job.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: navy)),
                ),
                if (job.paused)
                  const Chip(
                      label: Text('Paused', style: TextStyle(fontSize: 10)))
                else
                  Chip(
                    label: Text(job.stage.label,
                        style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Text('${job.company} • ${job.location}',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(analysis.label,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 7),
            Text(
                'Skill keyword overlap: ${analysis.matchScore}% • not an ATS guarantee',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
            if (analysis.blockers.isNotEmpty)
              Text('Restriction phrase: ${analysis.blockers.join(', ')}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFB91C1C))),
            if (analysis.signals.isNotEmpty)
              Text('Positive wording: ${analysis.signals.join(', ')}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9A5B00))),
            if (job.evidenceChecklistComplete)
              const Text(
                  'Evidence checklist entered — independently reconfirm before relying on it.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF0F766E))),
            if (job.description.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(job.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.35)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: [
                FilledButton.icon(
                  onPressed: isBlocked || job.paused
                      ? null
                      : () => _prepareJob(job),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('Prepare CV + letter'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showEvidenceDialog(job),
                  icon: const Icon(Icons.fact_check_outlined, size: 17),
                  label: const Text('Check evidence'),
                ),
                if (job.url.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _openUrl(job.url),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Original ad'),
                  ),
                TextButton.icon(
                  onPressed: () =>
                      _updateJob(job.copyWith(paused: !job.paused)),
                  icon: Icon(job.paused ? Icons.play_arrow : Icons.pause,
                      size: 16),
                  label: Text(job.paused ? 'Resume' : 'Pause'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddJob() async {
    final title = TextEditingController();
    final company = TextEditingController();
    final location = TextEditingController(text: 'Auckland');
    final url = TextEditingController();
    final source = TextEditingController(text: 'Manual import');
    final description = TextEditingController();

    final result = await showDialog<JobRecord>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import a vacancy'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Job title *')),
                const SizedBox(height: 8),
                TextField(controller: company, decoration: const InputDecoration(labelText: 'Employer / agency *')),
                const SizedBox(height: 8),
                TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 8),
                TextField(controller: source, decoration: const InputDecoration(labelText: 'Source')),
                const SizedBox(height: 8),
                TextField(controller: url, decoration: const InputDecoration(labelText: 'Original job URL'), keyboardType: TextInputType.url),
                const SizedBox(height: 8),
                TextField(
                  controller: description,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: 6000,
                  decoration: const InputDecoration(
                      labelText: 'Paste the full job description *',
                      alignLabelWithHint: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty ||
                  company.text.trim().isEmpty ||
                  description.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                dialogContext,
                JobRecord(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: title.text.trim(),
                  company: company.text.trim(),
                  location: location.text.trim(),
                  source: source.text.trim().isEmpty
                      ? 'Manual import'
                      : source.text.trim(),
                  url: url.text.trim(),
                  description: description.text.trim(),
                  createdAt: DateTime.now(),
                ),
              );
            },
            child: const Text('Analyse and save'),
          ),
        ],
      ),
    );

    for (final controller in [title, company, location, url, source, description]) {
      controller.dispose();
    }

    if (result != null) {
      setState(() => _jobs.insert(0, result));
      await _saveJobs();
      final analysis =
          JobAnalyzer.analyze(job: result, profileSkills: _profile.skills);
      _message('Job imported: ${analysis.label}.');
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: _profile.name);
    final email = TextEditingController(text: _profile.email);
    final phone = TextEditingController(text: _profile.phone);
    final location = TextEditingController(text: _profile.location);
    final summary = TextEditingController(text: _profile.summary);
    final experience = TextEditingController(text: _profile.experience);
    final qualifications = TextEditingController(text: _profile.qualifications);
    final skills = TextEditingController(text: _profile.skills.join(', '));

    final result = await showDialog<UserProfile>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit candidate profile'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name *')),
                const SizedBox(height: 8),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *')),
                const SizedBox(height: 8),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone / WhatsApp')),
                const SizedBox(height: 8),
                TextField(controller: location, decoration: const InputDecoration(labelText: 'Current location')),
                const SizedBox(height: 8),
                TextField(controller: summary, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'Professional summary')),
                const SizedBox(height: 8),
                TextField(controller: experience, maxLength: 1200, maxLines: 5, decoration: const InputDecoration(labelText: 'Real work experience (roles, dates, duties)')),
                const SizedBox(height: 8),
                TextField(controller: qualifications, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'Qualifications, licences and training')),
                const SizedBox(height: 8),
                TextField(controller: skills, maxLines: 3, decoration: const InputDecoration(labelText: 'Verified skills, comma-separated')),
                const SizedBox(height: 6),
                const Text(
                  'Do not add heavy-equipment operation, lifting capacity, safety tickets or trade skills unless you genuinely have them.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || !email.text.contains('@')) return;
              final skillList = skills.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList();
              Navigator.pop(
                dialogContext,
                _profile.copyWith(
                  name: name.text.trim(),
                  email: email.text.trim(),
                  phone: phone.text.trim(),
                  location: location.text.trim().isEmpty
                      ? 'Pakistan'
                      : location.text.trim(),
                  summary: summary.text.trim(),
                  experience: experience.text.trim(),
                  qualifications: qualifications.text.trim(),
                  skills: skillList,
                ),
              );
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    );

    for (final controller in [
      name, email, phone, location, summary, experience, qualifications, skills
    ]) {
      controller.dispose();
    }
    if (result != null) await _saveProfile(result);
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final savedPhoto = File('${directory.path}/profile-photo-${DateTime.now().millisecondsSinceEpoch}.jpg');
        await File(image.path).copy(savedPhoto.path);
        await _saveProfile(_profile.copyWith(photoPath: savedPhoto.path));
        _message('Profile photo saved on this device.');
      }
    } catch (_) {
      _message('Could not open the photo picker.');
    }
  }

  Future<void> _showEvidenceDialog(JobRecord job) async {
    bool accredited = job.employerAccredited;
    bool jobCheck = job.jobCheckConfirmed;
    final hours = TextEditingController(text: job.hoursPerWeek.toString());
    final evidence =
        TextEditingController(text: job.verificationEvidence);

    final updated = await showDialog<JobRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('AEWV evidence checklist'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Record evidence you have independently checked. These switches are your notes, not an automatic INZ verification.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  CheckboxListTile(
                    value: accredited,
                    onChanged: (value) =>
                        setDialogState(() => accredited = value ?? false),
                    title: const Text('Employer currently appears accredited'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: jobCheck,
                    onChanged: (value) =>
                        setDialogState(() => jobCheck = value ?? false),
                    title: const Text(
                        'Employer confirms approved job check for this vacancy'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextField(
                    controller: hours,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Guaranteed hours each week'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: evidence,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: 'Evidence / who confirmed / date'),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openUrl(_sources.last['url']!),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open official INZ employer search'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                job.copyWith(
                  employerAccredited: accredited,
                  jobCheckConfirmed: jobCheck,
                  hoursPerWeek: int.tryParse(hours.text) ?? 0,
                  verificationEvidence: evidence.text.trim(),
                ),
              ),
              child: const Text('Save evidence notes'),
            ),
          ],
        ),
      ),
    );
    hours.dispose();
    evidence.dispose();
    if (updated != null) {
      await _updateJob(updated);
      _message(updated.evidenceChecklistComplete
          ? 'Your evidence checklist is complete. Reconfirm before applying.'
          : 'Evidence notes saved.');
    }
  }

  Future<void> _prepareJob(JobRecord job) async {
    if (_profile.name.trim().isEmpty || !_profile.email.contains('@')) {
      _message('Add your full name and email in Profile before generating documents.');
      setState(() => _tab = 2);
      return;
    }
    try {
      await CvPdfService.preview(_profile, job);
      await _updateJob(job.copyWith(stage: ApplicationStage.prepared));
      _message('Two-page CV and cover letter prepared. Submit manually on the employer website.');
    } catch (_) {
      _message('PDF generation failed. Check the profile fields and try again.');
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 21),
            Text(value,
                style: const TextStyle(
                    fontSize: 25, fontWeight: FontWeight.w900, color: navy)),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black54, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _RegionPill extends StatelessWidget {
  const _RegionPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 34, color: amber),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 5),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }
}
