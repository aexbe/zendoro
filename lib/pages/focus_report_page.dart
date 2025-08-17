// lib/pages/focus_report_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/focus_report_service.dart';
import 'package:intl/intl.dart';

class FocusReportPage extends StatelessWidget {
  const FocusReportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FocusReportService(
          userBox: Hive.box('userBox'), usersBox: Hive.box('usersBox')),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    return Scaffold(
      appBar: AppBar(
        title: Text("Focus Report",
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.black87)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Progress",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            _SummaryRow(),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width - 30,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black26,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("All time",
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text("${s.totalHoursAllTime.toStringAsFixed(1)} h",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color.fromARGB(255, 0, 0, 0))),
                  const SizedBox(height: 6),
                  Text("Productivity ${s.productivityScore}/100",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(
              title: "30-day Trend Analysis",
              subtitle: "Visual overview of your last month focus journey.",
            ),
            _TrendCard(),
            const SizedBox(height: 16),
            _SectionHeader(
              title: "Weekly Habits",
              subtitle: "Understand your patterns and consistency better.",
            ),
            const SizedBox(height: 8),
            _WeekBar(),
            const SizedBox(height: 16),
            _SectionHeader(
              title: "Daily Habits",
              subtitle: "Understand your patterns and consistency better.",
            ),
            _HistogramCard(),
            const SizedBox(height: 16),
            _SectionHeader(
              title: "Focus Heatmap",
              subtitle: "Intensity map of your last 90 days focus effort.",
            ),
            _HeatmapCard(),
            const SizedBox(height: 16),
            _SectionHeader(
              title: "Streaks & Anomalies",
              subtitle: "Keep track of consistency and unusual days.",
            ),
            _StreaksAndAnomalies(),
            const SizedBox(height: 16),
            _SectionHeader(
              title: "Recent Sessions",
              subtitle: "Quick summary of your last 20 focus records.",
            ),
            _RecentSessionsTable(),
            const SizedBox(height: 16),
            //_ExportRow(),
            //const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: Colors.black54)),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    return Row(
      children: [
        Container(
          width: MediaQuery.of(context).size.width / 2 - 60 / 2,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black26,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today",
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 10),
              Text("${s.todayHours.toStringAsFixed(2)} h",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(255, 0, 0, 0))),
              const SizedBox(height: 6),
              Text(
                  "${(s.todayHours / s._dailyGoalOrDefault() * 100).toStringAsFixed(0)}% of goal",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: MediaQuery.of(context).size.width / 2 - 60 / 2,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black26,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Last 7 days",
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 10),
              Text("${s.last7DaysTotal.toStringAsFixed(1)} h",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(255, 0, 0, 0))),
              const SizedBox(height: 6),
              Text("Avg ${s.rolling7.toStringAsFixed(2)} h/day",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

extension on FocusReportService {
  num _dailyGoalOrDefault() {
    if (userBox.get('currentUser') == null ||
        userBox.get('currentUser')!.focusEntries == null ||
        userBox.get('currentUser')!.focusEntries!.isEmpty) {
      return 6.0;
    }
    return userBox
        .get('currentUser')!
        .focusEntries!
        .values
        .first
        .dailyFocusGoal;
  }
}

// Trend card with a line chart
class _TrendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    final points = List.generate(s.last30DaysList.length,
        (i) => FlSpot(i.toDouble(), s.last30DaysList[i]));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: (s.last30DaysList.isEmpty
                      ? 8.0
                      : (s.last30DaysList.reduce((a, b) => a > b ? a : b) + 2))
                  .clamp(4.0, 24.0),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
              ),
              lineBarsData: [
                LineChartBarData(
                    spots: points,
                    isCurved: true,
                    barWidth: 3,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        color: const Color.fromARGB(255, 0, 0, 0)
                            .withOpacity(0.1))),
              ],
            ))),
      ]),
    );
  }
}

// Week Bar chart
class _WeekBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    final labels = s.weekdayAvg.keys.toList(); // Mon..Sun
    final values = labels.map((l) => s.weekdayAvg[l] ?? 0.0).toList();
    final maxY =
        (values.isEmpty ? 8.0 : (values.reduce((a, b) => a > b ? a : b) + 1.0))
            .clamp(4.0, 24.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        SizedBox(
            height: 200,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
              barGroups: List.generate(
                  values.length,
                  (i) => BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                            toY: values[i],
                            width: 20,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            borderRadius: BorderRadius.circular(6))
                      ])),
              titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(labels[v.toInt()],
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.black54, fontSize: 12))))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 2,
                          getTitlesWidget: (v, meta) => Text(
                              v.toInt().toString(),
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.black54, fontSize: 10))))),
            ))),
      ]),
    );
  }
}

// Histogram chart
class _HistogramCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    final buckets = [0.0, 0.0, 0.0, 0.0, 0.0];
    for (final h in s.last30DaysList) {
      if (h < 0.5) {
        buckets[0]++;
      } else if (h < 1) {
        buckets[1]++;
      } else if (h < 2) {
        buckets[2]++;
      } else if (h < 4) {
        buckets[3]++;
      } else {
        buckets[4]++;
      }
    }
    final labels = ['<0.5h', '0.5-1h', '1-2h', '2-4h', '4h+'];
    final maxY = buckets.reduce((a, b) => a > b ? a : b).clamp(1.0, 30.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
              barGroups: List.generate(
                buckets.length,
                (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: buckets[i],
                      width: 20,
                      color: const Color.fromARGB(255, 0, 0, 0),
                      borderRadius: BorderRadius.circular(6))
                ]),
              ),
              titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) => Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(labels[v.toInt()],
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10, color: Colors.black54))))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 5,
                          getTitlesWidget: (v, meta) => Text(
                              v.toInt().toString(),
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.black54, fontSize: 10))))))),
        )
      ]),
    );
  }
}

// Heatmap: simplified calendar grid 7xN
class _HeatmapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    final now = DateTime.now();
    final days = List.generate(90, (i) => now.subtract(Duration(days: 89 - i)));
    final max = days
        .map((d) => s.heatmap[DateFormat('yyyy-MM-dd').format(d)] ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b)
        .clamp(1.0, 8.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Wrap(
            spacing: 4,
            runSpacing: 4,
            children: days.map((d) {
              final key = DateFormat('yyyy-MM-dd').format(d);
              final h = s.heatmap[key] ?? 0.0;
              final intensity = (h / max).clamp(0.0, 1.0);
              final color = Color.lerp(Colors.black12,
                  const Color.fromARGB(255, 0, 0, 0), intensity)!;
              return Tooltip(
                message:
                    '${DateFormat.yMMMd().format(d)} — ${h.toStringAsFixed(2)}h',
                child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(4))),
              );
            }).toList()),
      ]),
    );
  }
}

// Streaks and Anomalies cards
class _StreaksAndAnomalies extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    return Column(children: [
      Container(
          width: MediaQuery.of(context).size.width - 30,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black26,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Streaks',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Current streak:',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: Colors.black54)),
            Text('${s.currentStreak} days',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(255, 0, 0, 0))),
            const SizedBox(height: 12),
            Text('Longest streak:',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: Colors.black54)),
            Text('${s.longestStreak} days',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(255, 0, 0, 0))),
          ])),
      const SizedBox(height: 16),
      Container(
          width: MediaQuery.of(context).size.width - 30,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black26,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Anomalies (30d)',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            ...(s.anomalies.isEmpty
                ? [
                    Text('None detected',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.black54, fontSize: 14))
                  ]
                : s.anomalies.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '${DateFormat.yMMMd().format(a['date'])}: ${a['hours']}h (z=${a['z']})',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: a['z'] > 2 ? Colors.red : Colors.black87),
                      ),
                    ))) 
            //.toList()
          ])),
    ]);
  }
}

// Recent sessions table
class _RecentSessionsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<FocusReportService>();
    final rows = s.recentHistory.take(20).toList();
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black26,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recent sessions',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ]),
          const SizedBox(height: 8),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 8),
          ...rows.map((r) {
            final dt = r['date'] as DateTime;
            return ListTile(
              leading: Icon(Icons.access_time_filled, color: Colors.black54),
              title: Text(DateFormat.yMMMd().format(dt),
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
              subtitle: Text(
                  '${(r['hours'] as double).toStringAsFixed(2)} h of focus',
                  style: GoogleFonts.plusJakartaSans(color: Colors.black54)),
              trailing: IconButton(
                  icon: Icon(Icons.download_outlined, color: Colors.black54),
                  onPressed: () {
                    // export single day CSV / JSON
                    final csv =
                        'date,hours\n${DateFormat('yyyy-MM-dd').format(dt)},${(r['hours'] as double).toStringAsFixed(2)}';
                    // implement share/save
                  }),
            );
          }),
        ]));
  }
}

// Export buttons row
//class _ExportRow extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    final s = context.watch<FocusReportService>();
//    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
//      Expanded(
//        child: OutlinedButton.icon(
//            onPressed: () {
//              final csv = s.exportCsv();
//              // share/save
//            },
//            style: OutlinedButton.styleFrom(
//                side: BorderSide(color: Colors.black26),
//                padding:
//                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
//            icon: const Icon(Icons.download_outlined, color: Colors.black54),
//            label: Text('Export CSV',
//                style: GoogleFonts.plusJakartaSans(color: Colors.black87))),
//      ),
//      const SizedBox(width: 16),
//      Expanded(
//        child: ElevatedButton.icon(
//            onPressed: () {
//              final json = s.exportToJson();
//              // convert to file & share/save
//            },
//            style: ElevatedButton.styleFrom(
//                backgroundColor: Colors.black87,
//                padding:
//                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
//            icon: const Icon(Icons.file_upload, color: Colors.white),
//            label: Text('Export JSON',
//                style: GoogleFonts.plusJakartaSans(color: Colors.white))),
//      ),
//    ]);
//  }
//}
//