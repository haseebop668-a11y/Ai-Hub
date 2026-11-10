import 'package:flutter/material.dart';

import '../../data/local_database.dart';

class StudySettingsPage extends StatefulWidget {
  const StudySettingsPage({super.key});

  @override
  State<StudySettingsPage> createState() => _StudySettingsPageState();
}

class _StudySettingsPageState extends State<StudySettingsPage> {
  int _goalMinutes = 300;
  int _breakMinutes = 10;
  TimeOfDay? _startTime;
  bool _focusMode = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await LocalDatabase.instance.learnerProfile();
      if (!mounted) return;
      setState(() {
        _goalMinutes = (profile['daily_goal_minutes'] as int? ?? 300).clamp(30, 600).toInt();
        _breakMinutes = (profile['break_minutes'] as int? ?? 10).clamp(0, 60).toInt();
        final hour = profile['study_start_hour'] as int?;
        final minute = profile['study_start_minute'] as int?;
        _startTime = hour == null || minute == null
            ? null
            : TimeOfDay(hour: hour, minute: minute);
        _focusMode = profile['focus_mode_enabled'] == 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load study settings: $error')),
      );
    }
  }

  Future<void> _chooseStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (selected != null && mounted) setState(() => _startTime = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await LocalDatabase.instance.saveStudySettings(
        dailyGoalMinutes: _goalMinutes,
        breakMinutes: _breakMinutes,
        startHour: _startTime?.hour,
        startMinute: _startTime?.minute,
        focusModeEnabled: _focusMode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study preferences saved offline.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save settings: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study discipline')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DAILY ACTIVE STUDY TARGET',
                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text('${_goalMinutes ~/ 60} hr ${_goalMinutes % 60} min',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                        Slider(
                          value: _goalMinutes.toDouble(),
                          min: 30,
                          max: 600,
                          divisions: 19,
                          label: '$_goalMinutes min',
                          onChanged: (value) => setState(() => _goalMinutes = value.round()),
                        ),
                        const Text('Only active study time counts. Breaks and background time are excluded.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Preferred daily start time'),
                        subtitle: Text(_startTime?.format(context) ?? 'Not set yet'),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _chooseStartTime,
                      ),
                      if (_startTime != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _startTime = null),
                            child: const Text('Clear time'),
                          ),
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.free_breakfast_outlined),
                        title: const Text('Break between 50-minute blocks'),
                        subtitle: Text(_breakMinutes == 0 ? 'No planned break' : '$_breakMinutes minutes'),
                        trailing: DropdownButton<int>(
                          value: _breakMinutes,
                          items: const [0, 5, 10, 15, 20, 30].map((value) =>
                              DropdownMenuItem(value: value, child: Text('$value min'))).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _breakMinutes = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: _focusMode,
                    onChanged: (value) => setState(() => _focusMode = value),
                    secondary: const Icon(Icons.center_focus_strong_rounded),
                    title: const Text('In-app Focus Mode'),
                    subtitle: const Text('Keeps the study screen focused. It does not lock your phone or block emergency access.'),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.weekend_outlined),
                    title: Text('Weekly rest day'),
                    subtitle: Text('Sunday · no daily-target or streak penalty'),
                    trailing: Icon(Icons.check_circle_outline, color: Color(0xFF16845B)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your start time is saved as a preference. Scheduled notifications are not enabled by this settings page; they require a separate notification-permission and scheduling feature.',
                  style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF667085)),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save study settings'),
                ),
              ],
            ),
    );
  }
}
