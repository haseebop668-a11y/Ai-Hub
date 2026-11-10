import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local_database.dart';

class ActiveStudyTimerPage extends StatefulWidget {
  const ActiveStudyTimerPage({super.key});

  @override
  State<ActiveStudyTimerPage> createState() => _ActiveStudyTimerPageState();
}

class _ActiveStudyTimerPageState extends State<ActiveStudyTimerPage>
    with WidgetsBindingObserver {
  static const int _blockSeconds = 50 * 60;
  static const int _idleLimitSeconds = 180;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  DateTime? _startedDay;
  DateTime _lastInteraction = DateTime.now();
  int _savedSecondsToday = 0;
  int _elapsedSeconds = 0;
  bool _running = false;
  bool _saving = false;
  bool _idlePaused = false;
  bool _completed = false;

  bool get _isRestDay => DateTime.now().weekday == DateTime.sunday;
  int get _remainingSeconds => (_blockSeconds - _elapsedSeconds).clamp(0, _blockSeconds).toInt();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToday();
  }

  Future<void> _loadToday() async {
    final seconds = await LocalDatabase.instance.activeStudySecondsForDay(DateTime.now());
    if (!mounted) return;
    setState(() => _savedSecondsToday = seconds);
  }

  void _registerActivity() {
    _lastInteraction = DateTime.now();
    if (_idlePaused && !_running && !_completed) {
      setState(() => _idlePaused = false);
    }
  }

  void _startOrResume() {
    if (_isRestDay || _completed || _saving) return;
    _registerActivity();
    _startedDay ??= DateTime.now();
    _stopwatch.start();
    _running = true;
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() {});
  }

  void _pause({bool dueToIdle = false}) {
    if (!_running) return;
    _stopwatch.stop();
    _elapsedSeconds = _stopwatch.elapsed.inSeconds;
    _running = false;
    _idlePaused = dueToIdle;
    _ticker?.cancel();
    _ticker = null;
    if (mounted) setState(() {});
  }

  void _tick() {
    if (!_running || !mounted) return;
    if (DateTime.now().difference(_lastInteraction).inSeconds >= _idleLimitSeconds) {
      _pause(dueToIdle: true);
      return;
    }
    final elapsed = _stopwatch.elapsed.inSeconds;
    if (elapsed >= _blockSeconds) {
      _elapsedSeconds = _blockSeconds;
      _stopwatch.stop();
      _running = false;
      _ticker?.cancel();
      _ticker = null;
      setState(() {});
      _finish();
      return;
    }
    setState(() => _elapsedSeconds = elapsed);
  }

  Future<void> _finish() async {
    if (_saving || _elapsedSeconds <= 0) return;
    setState(() => _saving = true);
    _pause();
    final seconds = _elapsedSeconds;
    final day = _startedDay ?? DateTime.now();
    try {
      await LocalDatabase.instance.addActiveStudySeconds(day: day, seconds: seconds);
      if (!mounted) return;
      setState(() {
        _savedSecondsToday += seconds;
        _elapsedSeconds = 0;
        _completed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active study time saved on this device.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save study time: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _clock(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _elapsedSeconds / _blockSeconds;
    final totalToday = _savedSecondsToday + (_running ? _stopwatch.elapsed.inSeconds : _elapsedSeconds);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registerActivity(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Focused study block')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Text('50-MINUTE ACTIVE STUDY BLOCK',
                          style: TextStyle(fontSize: 11, letterSpacing: 1.2,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 12,
                                backgroundColor: const Color(0xFFECE7DD),
                                color: const Color(0xFFD97706),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_clock(_remainingSeconds),
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                const Text('remaining'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isRestDay)
                        const Text('Sunday is your weekly rest day. No study target or streak penalty today.',
                            textAlign: TextAlign.center)
                      else if (_completed)
                        const Text('Block complete. Your active study time has been saved.')
                      else if (_idlePaused)
                        const Text('Paused after 3 minutes without interaction. Tap Resume when you are ready.')
                      else if (!_running && _elapsedSeconds > 0)
                        const Text('Paused. Your active time is preserved until you finish this block.')
                      else if (!_running)
                        const Text('Only foreground study time is counted. Leaving the app pauses the timer.')
                      else
                        const Text('Stay in the app and work actively. Background time is not counted.'),
                      const SizedBox(height: 18),
                      if (!_completed && !_isRestDay)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saving ? null : (_running ? () => _pause() : _startOrResume),
                                icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                label: Text(_running ? 'Pause' : (_elapsedSeconds > 0 ? 'Resume' : 'Start')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _saving || _elapsedSeconds == 0 ? null : _finish,
                              child: const Text('Finish'),
                            ),
                          ],
                        ),
                      if (_saving) const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: const Text('Active study time saved today'),
                  subtitle: Text('${totalToday ~/ 60} minutes counted · break time excluded'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'The timer pauses when the app leaves the foreground and after 3 minutes without a touch. '
                  'Finish a block to save its active seconds to your offline study record.',
                  style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF667085)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
