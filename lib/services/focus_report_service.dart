// lib/services/focus_report_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/focus_entry_data.dart';

class FocusReportService extends ChangeNotifier {
  final Box<UserModel> userBox;
  final Box<UserModel> usersBox;

  UserModel? _user;
  Map<int, FocusEntryData> _map = {};

  // Computed caches
  double totalHoursAllTime = 0.0;
  double todayHours = 0.0;
  double last7DaysTotal = 0.0;
  double last30DaysTotal = 0.0;
  List<double> last7DaysList = [];
  List<double> last30DaysList = [];
  Map<String, double> weekdayAvg = {}; // Mon..Sun -> avg hours
  Map<String, double> heatmap = {}; // yyyy-MM-dd -> hours
  List<Map<String, dynamic>> recentHistory = []; // [{date, hours}]
  double rolling7 = 0.0;
  double rolling30 = 0.0;
  int longestStreak = 0;
  int currentStreak = 0;
  double productivityScore = 0.0;
  List<Map<String, dynamic>> anomalies = []; // {date, hours, zscore}

  FocusReportService({required this.userBox, required this.usersBox}) {
    _loadUserAndCompute();
  }

  Future<void> refresh() async {
    await _loadUserAndCompute();
  }

  Future<void> _loadUserAndCompute() async {
    _user = userBox.get('currentUser');
    if (_user == null) return;
    _map = _user!.focusEntries ?? {};
    _computeAll();
    notifyListeners();
  }

  // Utility: convert yyyymmdd int -> DateTime
  DateTime _fromKey(int k) {
    return DateTime(k ~/ 10000, (k % 10000) ~/ 100, k % 100);
  }

  String _fmtKey(int k) {
    final dt = _fromKey(k);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  void _computeAll() {
    totalHoursAllTime = 0.0;
    heatmap = {};
    recentHistory = [];
    last7DaysList = [];
    last30DaysList = [];

    // Build sorted list of entries by key ascending
    final keys = _map.keys.toList()..sort();

    for (final k in keys) {
      final f = _map[k]!;
      totalHoursAllTime += (f.dailyFocus);
      heatmap[_fmtKey(k)] = f.dailyFocus;
      recentHistory.add({'dateKey': k, 'date': _fromKey(k), 'hours': f.dailyFocus});
    }

    // Today
    final todayKey = _yyyymmdd(DateTime.now());
    todayHours = (_map[todayKey]?.dailyFocus ?? 0.0);

    // Last 7 and 30 days arrays (ordered oldest -> newest)
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final k = _yyyymmdd(d);
      final h = _map[k]?.dailyFocus ?? 0.0;
      last7DaysList.add(h);
    }
    last7DaysTotal = last7DaysList.fold(0.0, (a, b) => a + b);

    for (int i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final k = _yyyymmdd(d);
      final h = _map[k]?.dailyFocus ?? 0.0;
      last30DaysList.add(h);
    }
    last30DaysTotal = last30DaysList.fold(0.0, (a, b) => a + b);

    // Weekday averages (Mon..Sun)
    final wk = {'Mon': <double>[], 'Tue': <double>[], 'Wed': <double>[], 'Thu': <double>[], 'Fri': <double>[], 'Sat': <double>[], 'Sun': <double>[]};
    for (final kv in recentHistory) {
      final dt = kv['date'] as DateTime;
      final h = kv['hours'] as double;
      final label = DateFormat('E').format(dt); // Mon/Tue...
      wk[label]?.add(h);
    }
    weekdayAvg = {};
    wk.forEach((k, list) {
      weekdayAvg[k] = list.isEmpty ? 0.0 : (list.fold(0.0, (a, b) => a + b) / list.length);
    });

    // Rolling averages
    rolling7 = last7DaysList.isEmpty ? 0.0 : (last7DaysList.fold(0.0, (a, b) => a + b) / last7DaysList.length);
    rolling30 = last30DaysList.isEmpty ? 0.0 : (last30DaysList.fold(0.0, (a, b) => a + b) / last30DaysList.length);

    // Streaks
    _computeStreaks();

    // Productivity score: example composite (weights configurable)
    productivityScore = _computeProductivityScore();

    // Anomaly detection (z-score over last 30 days)
    anomalies = _detectAnomalies();

    // Keep recentHistory ordered newest first for UI
    recentHistory.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  int _yyyymmdd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  void _computeStreaks({double thresholdHours = 0.1}) {
    final now = DateTime.now();
    final map = _map;
    // iterate days from earliest to latest (so we can compute consecutive runs)
    final dayKeys = map.keys.toList()..sort();
    int maxStreak = 0;
    int curStreak = 0;
    DateTime? prev;
    for (final k in dayKeys) {
      final d = _fromKey(k);
      // only consider up to today
      if (d.isAfter(now)) continue;
      final hours = map[k]?.dailyFocus ?? 0.0;
      if (hours >= thresholdHours) {
        if (prev == null) {
          curStreak = 1;
        } else {
          // if day is consecutive
          if (d.difference(prev).inDays == 1) {
            curStreak++;
          } else {
            curStreak = 1;
          }
        }
        if (curStreak > maxStreak) maxStreak = curStreak;
      } else {
        curStreak = 0;
      }
      prev = d;
    }

    longestStreak = maxStreak;

    // Current streak: starting from today backward
    int cur = 0;
    for (int i = 0; i < 365; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final k = _yyyymmdd(d);
      final h = map[k]?.dailyFocus ?? 0.0;
      if (h >= thresholdHours) {
        cur++;
      } else {
        break;
      }
    }
    currentStreak = cur;
  }

  double _computeProductivityScore() {
    // Simple weighted score:
    // consistency (rolling7 > 0), intensity (rolling30 average), frequency (days with > threshold)
    final consistency = rolling7; // average over last 7 days
    final intensity = rolling30; // average over last 30 days
    final freqDays = last30DaysList.where((h) => h >= 0.5).length; // days >= 0.5h
    // normalize and combine
    final c = (consistency / (_user?.focusEntries?.length == 0 ? 1 : ( _dailyGoalOrDefault() ))) .clamp(0.0, 2.0);
    final i = (intensity / _dailyGoalOrDefault()).clamp(0.0, 2.0);
    final f = (freqDays / 30.0).clamp(0.0, 1.0);
    final score = (c * 0.4 + i * 0.4 + f * 0.2) * 50; // scale to 0-100 approx
    return double.parse(score.toStringAsFixed(1));
  }

  double _dailyGoalOrDefault() => _user?.focusEntries?.values.first.dailyFocusGoal ?? 6.0;

  List<Map<String, dynamic>> _detectAnomalies() {
    // z-score over last 30 days: z = (x - mean)/std
    final data = last30DaysList;
    if (data.isEmpty) return [];
    final mean = data.fold(0.0, (a, b) => a + b) / data.length;
    final variance = data.fold(0.0, (a, b) => a + (b - mean) * (b - mean)) / data.length;
    final std = sqrt(variance);
    final anomalies = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 0; i < data.length; i++) {
      final v = data[i];
      if (std == 0) continue;
      final z = (v - mean) / std;
      if (z.abs() >= 2.0) {
        // map to actual date
        final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i));
        anomalies.add({'date': d, 'hours': v, 'z': double.parse(z.toStringAsFixed(2))});
      }
    }
    return anomalies;
  }

  // Exports
  Map<String, dynamic> exportToJson() {
    final entries = _map.map((k, v) => MapEntry(k.toString(), {
      'dailyFocus': v.dailyFocus,
      'weeklyFocus': v.weeklyFocus,
      'totalFocus': v.totalFocus,
      'dailyFocusGoal': v.dailyFocusGoal,
    }));
    return {
      'meta': {
        'exportedAt': DateTime.now().toIso8601String(),
        'user': _user?.email ?? 'guest'
      },
      'entries': entries,
      'totals': {'totalHours': totalHoursAllTime}
    };
  }

  String exportCsv() {
    final sb = StringBuffer();
    sb.writeln('date,yyyyMMdd,hours,dailyGoal');
    final keys = _map.keys.toList()..sort();
    for (final k in keys) {
      final dt = _fromKey(k);
      final f = _map[k]!;
      sb.writeln('${DateFormat('yyyy-MM-dd').format(dt)},$k,${f.dailyFocus},${f.dailyFocusGoal}');
    }
    return sb.toString();
  }

  // optional import (json map)
  Future<void> importFromJson(Map<String, dynamic> data) async {
    // implement merging or replacing behavior as needed
    // simple merge:
    final entries = data['entries'] as Map<String, dynamic>? ?? {};
    for (final e in entries.entries) {
      final k = int.tryParse(e.key);
      if (k == null) continue;
      final obj = e.value as Map<String, dynamic>;
      _user!.focusEntries ??= {};
      _user!.focusEntries![k] = FocusEntryData(
        dailyFocus: (obj['dailyFocus'] ?? 0.0).toDouble(),
        weeklyFocus: (obj['weeklyFocus'] ?? 0.0).toDouble(),
        totalFocus: (obj['totalFocus'] ?? 0.0).toDouble(),
        dailyFocusGoal: (obj['dailyFocusGoal'] ?? _dailyGoalOrDefault()).toDouble(),
      );
    }
    await userBox.put('currentUser', _user!);
    await _loadUserAndCompute();
  }
  // public getter for UI use
double get dailyGoal {
  if (_user?.focusEntries == null || _user!.focusEntries!.isEmpty) return 6.0;
  return _user!.focusEntries!.values.first.dailyFocusGoal;
}

}
