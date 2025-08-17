// lib/pages/focus_page.dart
import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zendoro/pages/focus_report_page.dart';

import '../models/focus_entry_data.dart';
import '../models/user_model.dart';

/// Monochrome, robust, and per-user Pomodoro / Focus tracker.
/// - Data persists in SharedPreferences (session state) + Hive (per-user history).
/// - All focus amounts are stored as **HOURS** (double).
/// - Modes: Focus (count up), Short/Long Break (count down), Rapid Fire (count up, lap-free).
enum _Mode { focus, shortBreak, longBreak, rapidFire }

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});
  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  // ===== UI THEME (monochrome)
  static const _ink = Colors.black87;
  static const _inkSoft = Colors.black54;
  static const _bg = Colors.white;
  static const _panel = Color(0xFFF6F6F6);
  static const _divider = Color(0xFFE6E6E6);
  final double _r = 12;

  // ===== Timer configuration (defaults)
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  double _dailyGoalHours = 6.0;

  // ===== Timer state
  _Mode _mode = _Mode.focus;
  bool _running = false;
  bool _paused = false;

  // We keep a simple, reliable session model:
  // - For Focus/RapidFire (count-up): _accumulatedSec + (now - _runStartedAt)
  // - For Breaks (count-down): remainingSec = total - (now - _runStartedAt)
  DateTime? _runStartedAt;
  int _accumulatedSec =
      0; // sum of previous runs in this session (focus/rapidFire)
  int _remainingSec = 0; // live remaining for break sessions
  int _remainingAtSessionStart = 0;

  Timer? _ticker;

  // ===== Persistence boxes
  late Box<UserModel> _userBox; // 'userBox' (singleton current user)
  late Box<UserModel> _usersBox; // 'usersBox' (by email)
  UserModel? _user;

  // ===== Weekly + history cache
  Map<String, double> _weekHours = {}; // Mon..Sun -> hours (double)
  List<_HistoryRow> _history = [];

  // ===== SharedPrefs keys
  static const _kMode = 'fp_mode';
  static const _kRun = 'fp_running';
  static const _kPaused = 'fp_paused';
  static const _kStartIso = 'fp_start_iso';
  static const _kAccum = 'fp_accum';
  static const _kRemain = 'fp_remain';
  static const _kFocusMin = 'fp_focus_min';
  static const _kShortMin = 'fp_short_min';
  static const _kLongMin = 'fp_long_min';
  static const _kGoal = 'fp_goal';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _savePrefs();
    }
  }

  Future<void> _bootstrap() async {
    _userBox = Hive.box<UserModel>('userBox');
    _usersBox = Hive.box<UserModel>('usersBox');

    _user = _userBox.get('currentUser');
    // Safe default guest if not present (keeps app usable)
    _user ??= UserModel(
      name: 'Guest',
      email: '',
      password: '',
      gender: '',
      age: 0,
    );

    await _loadPrefs();

    // Initialize break remaining if needed
    if (!_running && !_paused && _remainingSec <= 0) {
      _resetRemainingForMode(_mode);
    }

    _rebuildWeeklyAndHistory();
    setState(() {});
  }

  // ===== SharedPreferences state
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _mode = _Mode.values[p.getInt(_kMode) ?? 0];
    _running = p.getBool(_kRun) ?? false;
    _paused = p.getBool(_kPaused) ?? false;
    _accumulatedSec = p.getInt(_kAccum) ?? 0;
    _remainingSec = p.getInt(_kRemain) ?? 0;
    final startIso = p.getString(_kStartIso);
    if (startIso != null) _runStartedAt = DateTime.tryParse(startIso);

    _focusMinutes = p.getInt(_kFocusMin) ?? _focusMinutes;
    _shortBreakMinutes = p.getInt(_kShortMin) ?? _shortBreakMinutes;
    _longBreakMinutes = p.getInt(_kLongMin) ?? _longBreakMinutes;
    _dailyGoalHours = p.getDouble(_kGoal) ?? _dailyGoalHours;

    if (_running && _runStartedAt != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_runStartedAt!).inSeconds;

      if (_isCountUpMode(_mode)) {
        // Focus & RapidFire — resume elapsed count
        _accumulatedSec += elapsed;
      } else {
        // Breaks — resume countdown
        final total = _totalSecondsFor(_mode);
        if (_remainingSec <= 0 || _remainingSec > total) {
          _remainingSec = total;
        }
        _remainingSec = max(0, _remainingSec - elapsed);
        _remainingAtSessionStart = min(total, _remainingSec + elapsed);
      }
    }

    // If nothing running/paused, set defaults
    if (!_running && !_paused) {
      if (_isCountUpMode(_mode)) {
        _accumulatedSec = 0;
      } else {
        _resetRemainingForMode(_mode);
      }
    }

    if (_running) _startTicker();
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kMode, _mode.index);
    await p.setBool(_kRun, _running);
    await p.setBool(_kPaused, _paused);
    await p.setInt(_kAccum, _accumulatedSec);
    await p.setInt(_kRemain, _remainingSec);
    if (_runStartedAt != null) {
      await p.setString(_kStartIso, _runStartedAt!.toIso8601String());
    } else {
      await p.remove(_kStartIso);
    }
    await p.setInt(_kFocusMin, _focusMinutes);
    await p.setInt(_kShortMin, _shortBreakMinutes);
    await p.setInt(_kLongMin, _longBreakMinutes);
    await p.setDouble(_kGoal, _dailyGoalHours);
  }

  // ===== Mode helpers
  bool _isCountUpMode(_Mode m) =>
      m == _Mode.rapidFire; // only RapidFire counts up

  void _resetRemainingForMode(_Mode m) {
    switch (m) {
      case _Mode.focus:
        _remainingSec = _focusMinutes * 60;
        break;
      case _Mode.shortBreak:
        _remainingSec = _shortBreakMinutes * 60;
        break;
      case _Mode.longBreak:
        _remainingSec = _longBreakMinutes * 60;
        break;
      case _Mode.rapidFire:
        _remainingSec = 0;
        break;
    }
  }

  int _totalSecondsFor(_Mode m) {
    switch (m) {
      case _Mode.shortBreak:
        return _shortBreakMinutes * 60;
      case _Mode.longBreak:
        return _longBreakMinutes * 60;
      case _Mode.focus:
        return _focusMinutes * 60;
      case _Mode.rapidFire:
        return 0; // not used
    }
  }

  // ===== Timer controls
  void _start() {
    if (_running) return;

    if (!_paused) {
      _resetRemainingForMode(_mode); // set full duration for Focus/Breaks
      _accumulatedSec = 0; // fresh run for RapidFire
    }

    _running = true;
    _paused = false;
    _runStartedAt = DateTime.now();

    if (_mode != _Mode.rapidFire) {
      _remainingAtSessionStart = _remainingSec; // anchor for pause/resume
    }

    _startTicker();
    _savePrefs();
    setState(() {});
  }

  void _pause() {
    if (!_running) return;
    final now = DateTime.now();

    if (_mode == _Mode.rapidFire) {
      // accumulate elapsed across pauses
      _accumulatedSec += now.difference(_runStartedAt ?? now).inSeconds;
    } else {
      final elapsed = now.difference(_runStartedAt ?? now).inSeconds;
      _remainingSec = max(0, _remainingAtSessionStart - elapsed);
    }

    _running = false;
    _paused = true;
    _stopTicker();
    _savePrefs();
    setState(() {});
  }

  void _resume() {
    if (!_paused) return;

    _paused = false;
    _running = true;
    _runStartedAt = DateTime.now();

    if (_mode != _Mode.rapidFire) {
      _remainingAtSessionStart =
          _remainingSec; // continue from frozen remaining
    }

    _startTicker();

    _savePrefs();
    setState(() {});
  }

  Future<void> _stop({bool save = true}) async {
    int secondsToRecord = 0;

    if (_mode == _Mode.rapidFire) {
      final extra = _running
          ? DateTime.now().difference(_runStartedAt ?? DateTime.now()).inSeconds
          : 0;
      secondsToRecord = _accumulatedSec + extra;
    } else {
      if (_running && _runStartedAt != null) {
        final elapsed = DateTime.now().difference(_runStartedAt!).inSeconds;
        secondsToRecord = max(0, min(_remainingAtSessionStart, elapsed));
      } else {
        secondsToRecord = max(0, _remainingAtSessionStart - _remainingSec);
      }
    }

    // IMPORTANT: store **hours**
    if (save &&
        secondsToRecord > 0 &&
        (_mode == _Mode.focus || _mode == _Mode.rapidFire)) {
      await _addHoursToToday(secondsToRecord / 3600.0);
    }

    _running = false;
    _paused = false;
    _runStartedAt = null;
    _accumulatedSec = 0;
    _stopTicker();
    _resetRemainingForMode(_mode);
    await _savePrefs();
    _rebuildWeeklyAndHistory();
    setState(() {});
  }

  Future<void> _onAutoComplete() async {
    final secondsRanThisSession = _remainingAtSessionStart; // from start to 0
    if (_mode == _Mode.focus && secondsRanThisSession > 0) {
      await _addHoursToToday(secondsRanThisSession / 3600.0); // hours!
    }

    _mode = (_mode == _Mode.focus) ? _Mode.shortBreak : _Mode.focus;

    _running = false;
    _paused = false;
    _runStartedAt = null;
    _stopTicker();
    _resetRemainingForMode(_mode);
    await _savePrefs();
    _rebuildWeeklyAndHistory();
    setState(() {});
  }

  void _resetSession() {
    _running = false;
    _paused = false;
    _runStartedAt = null;
    _accumulatedSec = 0;
    _resetRemainingForMode(_mode);
    _stopTicker();
    _savePrefs();
    setState(() {});
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;

      final now = DateTime.now();

      if (_mode == _Mode.rapidFire) {
        // Stopwatch-like; UI will read elapsed via sessionStart
        setState(() {});
        return;
      }

      // Countdown modes
      final elapsed = now.difference(_runStartedAt ?? now).inSeconds;
      final newRem = max(0, _remainingAtSessionStart - elapsed);
      if (newRem != _remainingSec) {
        _remainingSec = newRem;
        if (_remainingSec == 0) {
          _onAutoComplete();
          return;
        }
        setState(() {});
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ===== Data (Hive) – store HOURS
  Future<void> _addHoursToToday(double hours) async {
    // Load latest user reference
    _user = _userBox.get('currentUser') ?? _user;

    _user!.focusEntries ??= {};
    final todayKey = _yyyymmdd(DateTime.now());

    final existing = _user!.focusEntries![todayKey];
    if (existing != null) {
      existing.dailyFocus = (existing.dailyFocus) + hours;
      existing.totalFocus = (existing.totalFocus) + hours;
      existing.dailyFocusGoal = _dailyGoalHours;
    } else {
      _user!.focusEntries![todayKey] = FocusEntryData(
        dailyFocus: hours,
        weeklyFocus: 0.0,
        totalFocus: (_user!.totalFocusAccumulated ?? 0.0) + hours,
        dailyFocusGoal: _dailyGoalHours,
      );
    }

    // update aggregate on user
    _user!.totalFocusAccumulated =
        (_user!.totalFocusAccumulated ?? 0.0) + hours;

    // persist to both boxes (keep in sync when email known)
    final emailKey = (_user!.email).trim().toLowerCase();
    if (emailKey.isNotEmpty) {
      await _usersBox.put(emailKey, _user!);
    }
    await _userBox.put('currentUser', _user!);

    _rebuildWeeklyAndHistory();
  }

  int _yyyymmdd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  void _rebuildWeeklyAndHistory() {
    _weekHours = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0
    };
    _history = [];

    if (_user == null ||
        _user!.focusEntries == null ||
        _user!.focusEntries!.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    final last7 =
        List.generate(7, (i) => startDay.subtract(Duration(days: 6 - i)));

    final map = _user!.focusEntries!;
    for (final day in last7) {
      final k = _yyyymmdd(day);
      final item = map[k];
      final h = (item?.dailyFocus ?? 0.0);
      _weekHours[DateFormat('E').format(day)] = h;
      if (h > 0) {
        _history.add(_HistoryRow(day, h));
      }
    }

    // additional older records (up to 30 total)
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final k in keys) {
      final d = DateTime(k ~/ 10000, (k % 10000) ~/ 100, k % 100);
      if (d.isBefore(startDay.subtract(const Duration(days: 6)))) {
        _history.add(_HistoryRow(d, map[k]!.dailyFocus));
        if (_history.length > 30) break;
      }
    }
  }

  // ===== UI helpers
  String _fmtMMSS(int s) {
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _fmtHours(double h) {
    final hh = h.floor();
    final mm = ((h - hh) * 60).round();
    return '${hh}h ${mm}m';
  }

  double _todayHours() {
    final k = _yyyymmdd(DateTime.now());
    return _user?.focusEntries?[k]?.dailyFocus ?? 0.0;
  }

  // ===== Settings dialog
  void _openSettings() {
    final f = TextEditingController(text: _focusMinutes.toString());
    final s = TextEditingController(text: _shortBreakMinutes.toString());
    final l = TextEditingController(text: _longBreakMinutes.toString());
    final g = TextEditingController(text: _dailyGoalHours.toStringAsFixed(1));
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Timer Settings'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numField(f, 'Pomodoro (minutes)'),
              _numField(s, 'Short break (minutes)'),
              _numField(l, 'Long break (minutes)'),
              _numField(g, 'Daily goal (hours)', allowDecimal: true),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (key.currentState!.validate()) {
                _focusMinutes = int.parse(f.text.trim());
                _shortBreakMinutes = int.parse(s.text.trim());
                _longBreakMinutes = int.parse(l.text.trim());
                _dailyGoalHours = double.parse(g.text.trim());

                // 🛠 If timer is idle (not running and not paused), reset remaining time for current mode
                if (!_running && !_paused) {
                  _resetRemainingForMode(_mode);
                }

                await _savePrefs();
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _numField(TextEditingController c, String label,
      {bool allowDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          return allowDecimal
              ? (double.tryParse(v) == null ? 'Invalid' : null)
              : (int.tryParse(v) == null ? 'Invalid' : null);
        },
      ),
    );
  }

  // ===== UI components
  Widget _modeTabs() {
    final items = <_Mode, String>{
      _Mode.focus: 'Pomodoro',
      _Mode.shortBreak: 'Short',
      _Mode.longBreak: 'Long',
      _Mode.rapidFire: 'Focus',
    };
    return Row(
      children: items.entries.map((e) {
        final sel = _mode == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              if (_running || _paused) return; // lock during a session
              setState(() {
                _mode = e.key;
                _resetRemainingForMode(_mode);
                _remainingAtSessionStart = _remainingSec;
              });
              await _savePrefs();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? _ink : _panel,
                borderRadius: BorderRadius.circular(_r),
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.plusJakartaSans(
                    color: sel ? Colors.white : _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timerCard() {
    // compute display time
    String timerText;

    if (_mode == _Mode.rapidFire) {
      final s = _running
          ? DateTime.now().difference(_runStartedAt ?? DateTime.now()).inSeconds
          : 0;
      timerText = _fmtMMSS(s);
    } else {
      timerText = _fmtMMSS(_remainingSec); // Focus/Breaks countdown
    }

    final today = _todayHours();
    final pct =
        _dailyGoalHours <= 0 ? 0.0 : (today / _dailyGoalHours).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(_r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: _divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // top row: today + progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtHours(today),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: _ink)),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}% of ${_dailyGoalHours.toStringAsFixed(1)}h',
                    style: GoogleFonts.inter(color: _inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // big timer
          Text(
            timerText,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 56, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 6),
          Text(
            _mode == _Mode.rapidFire ? 'FOCUS SESSION' : _mode.name.toUpperCase(),
            style: GoogleFonts.inter(letterSpacing: 1, color: _inkSoft),
          ),
          const SizedBox(height: 16),
          // progress bar (daily goal)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDEDED),
              color: pct >= 1.0 ? Colors.black : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_running && !_paused) ...[
                _solidBtn('Start', _start),
                const SizedBox(width: 10),
                _outlineBtn('Settings', _openSettings),
              ] else if (_running) ...[
                if (_mode != _Mode.rapidFire) // Hide pause in rapid mode
                  _solidBtn('Pause', _pause, color: Colors.black87),
                if (_mode != _Mode.rapidFire) const SizedBox(width: 10),
                _outlineBtn('Stop & Save', () => _stop(save: true)),
              ] else if (_paused) ...[
                _solidBtn('Resume', _resume),
                const SizedBox(width: 10),
                _outlineBtn('Reset', _resetSession),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyBar() {
    final labels = _weekHours.keys.toList();
    final vals = _weekHours.values.toList();
    final maxY = max(1.0, (vals.isEmpty ? 1.0 : vals.reduce(max)) + 1.0);

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(_r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
        ],
        border: Border.all(color: _divider),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 days',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) {
                      return FlLine(color: _divider, strokeWidth: 1);
                    }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, (maxY / 4).floorToDouble())),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i],
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500, color: _ink));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(vals.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: vals[i],
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: vals[i] >= _dailyGoalHours
                            ? Colors.black
                            : Colors.black87,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyList() {
    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Text('No sessions recorded yet',
            style: GoogleFonts.inter(color: _inkSoft)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(_r),
        border: Border.all(color: _divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _divider),
        itemBuilder: (_, i) {
          final row = _history[i];
          return ListTile(
            dense: true,
            title: Text(_fmtHours(row.hours),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: _ink)),
            subtitle: Text(DateFormat.yMMMd().format(row.date),
                style: GoogleFonts.inter(color: _inkSoft)),
            trailing: Text(row.hours >= _dailyGoalHours ? 'Goal ✓' : '',
                style: GoogleFonts.inter(color: _ink)),
          );
        },
      ),
    );
  }

  // ===== Small buttons
  Widget _solidBtn(String text, VoidCallback onTap,
      {Color color = Colors.black}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
    );
  }

  Widget _outlineBtn(String text, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        side: const BorderSide(color: _ink),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
    );
  }

  // ===== Build
  @override
  Widget build(BuildContext context) {
    refresh() {
      _user = _userBox.get('currentUser') ?? _user;
      _rebuildWeeklyAndHistory();
      setState(() {});
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('Focus & Pomodoro',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Rebuild weekly data',
            icon: const Icon(Icons.refresh, color: _ink),
            onPressed: refresh,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: _ink),
            onPressed: _running ? null : _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modeTabs(),
              const SizedBox(height: 12),
              _timerCard(),
              const SizedBox(height: 14),
              _weeklyBar(),
              const SizedBox(height: 14),
              Text(
                'History',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _historyList(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FocusReportPage()),
                  );
                },
                child: Text(
                  'Get a detailed report ->',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'All times are stored per user (local Hive).',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Simple model for UI history rows
class _HistoryRow {
  final DateTime date;
  final double hours; // HOURS
  _HistoryRow(this.date, this.hours);
}
