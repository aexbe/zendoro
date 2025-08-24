// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:zendoro/models/user_model.dart';
import 'package:zendoro/models/tasks_entry_data.dart'; // make sure this path matches your project
import 'package:zendoro/services/focus_report_service.dart';
import 'package:hive/hive.dart';
import 'package:zendoro/pages/auth/lobby.dart';
import 'package:zendoro/pages/quotes/quote_manager.dart';
import 'package:zendoro/pages/about_page.dart';
import 'package:zendoro/pages/daily_log.dart';
import 'package:zendoro/pages/help_page.dart';
import 'package:zendoro/pages/pomodoro_focus.dart';
import 'package:zendoro/pages/routine.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<UserModel>('userBox');
    final usersBox =
        Hive.isBoxOpen('usersBox') ? Hive.box<UserModel>('usersBox') : userBox;
    final user = userBox.get('currentUser');

    String getFirstWord(String? sentence) {
      final trimmedSentence = sentence?.trim();

      if (trimmedSentence == null) {
        return "Guest";
      }
      final words = trimmedSentence.split(' ');
      return words[0];
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomePageService()),
        ChangeNotifierProvider(
          create: (_) =>
              FocusReportService(userBox: userBox, usersBox: usersBox),
        ),
      ],
      child: Consumer2<HomePageService, FocusReportService>(
        builder: (context, service, focusService, child) {
          if (service.isLoading) {
            return const LoadingScaffold(message: 'Loading your dashboard...');
          }

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 70,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome, ${getFirstWord(user?.name)} 👋",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, color: Colors.black.withOpacity(0.6))),
                ],
              ),
            ),
            drawer: AppDrawer(user: user),
            body: RefreshIndicator(
              onRefresh: () async {
                await context.read<HomePageService>().reload();
                await context.read<FocusReportService>().refresh();
              },
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _TodaySummary(service: service, focusService: focusService),
                  const SizedBox(height: 18),
                  _FocusOverview(focusService: focusService),
                  const SizedBox(height: 18),
                  _TasksOverview(service: service),
                  const SizedBox(height: 18),
                  _JournalHighlight(),
                  const SizedBox(height: 18),
                  _MotivationBlock(quote: service.dailyQuote),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Drawer ----------------
class AppDrawer extends StatelessWidget {
  final UserModel? user;
  const AppDrawer({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    Uint8List? imgBytes = user?.profilePicBytes != null
        ? Uint8List.fromList(user!.profilePicBytes!)
        : null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Guest',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            accountEmail:
                Text(user?.email ?? '', style: GoogleFonts.plusJakartaSans()),
            currentAccountPicture: CircleAvatar(
              backgroundImage: imgBytes != null ? MemoryImage(imgBytes) : null,
              child:
                  imgBytes == null ? const Icon(Icons.person, size: 40) : null,
            ),
            decoration: BoxDecoration(color: Colors.black87.withOpacity(0.85)),
          ),
          _drawerItem(context, 'Daily Log', Icons.book_outlined, JournalPage()),
          _drawerItem(context, 'Pomodoro / Focus', Icons.timer_outlined,
              const FocusPage()),
          _drawerItem(context, 'Task Planner', Icons.task_alt_outlined,
              const RoutinePlannerWidget()),
          const Divider(),
          _drawerItem(
              context, 'Help & Tutorial', Icons.help_outline, const HelpPage()),
          _drawerItem(context, 'About', Icons.info_outline, const AboutPage()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('Sign Out',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, color: Colors.red)),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? You will need to re-enter your details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final box = Hive.box<UserModel>('userBox');
              await box.delete('currentUser');
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Lobby()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------- Service ----------------
class HomePageService extends ChangeNotifier {
  bool isLoading = true;
  String dailyQuote = "";

  List<TasksEntryData> tasks = [];
  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.completed).length;

  HomePageService() {
    reload();
  }

  Future<void> reload() async {
    dailyQuote = await QuoteManager.getDailyQuote();

    // Load tasks from Hive
    final box = Hive.box<UserModel>('userBox');
    final user = box.get('currentUser');
    if (user != null) {
      tasks = (user.tasks ?? []).cast<TasksEntryData>();
    } else {
      tasks = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTask(int index) async {
    if (index < 0 || index >= tasks.length) return;
    final box = Hive.box<UserModel>('userBox');
    final user = box.get('currentUser');
    if (user == null) return;

    final old = tasks[index];
    final updated = TasksEntryData(
      task: old.task,
      completed: !old.completed,
      duration: old.duration,
    );

    tasks[index] = updated;
    user.tasks = tasks;
    await box.put('currentUser', user);
    notifyListeners();
  }
}

// ---------------- Widgets ----------------

class _TodaySummary extends StatelessWidget {
  final HomePageService service;
  final FocusReportService focusService;
  const _TodaySummary({required this.service, required this.focusService});

  @override
  Widget build(BuildContext context) {
    final todayFocus = focusService.todayHours;
    final weeklyFocus = focusService.last7DaysTotal;
    final completed = service.completedTasks;
    final total = service.totalTasks;

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Snapshot",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                  label: "Focus Today",
                  value: "${todayFocus.toStringAsFixed(1)} hrs"),
              _SummaryItem(
                  label: "Weekly Focus",
                  value: "${weeklyFocus.toStringAsFixed(1)} hrs"),
              _SummaryItem(label: "Tasks Done", value: "$completed/$total"),
            ],
          )
        ],
      ),
    );
  }
}

class _FocusOverview extends StatelessWidget {
  final FocusReportService focusService;
  const _FocusOverview({required this.focusService});

  @override
  Widget build(BuildContext context) {
    final goal = focusService.dailyGoal.clamp(0.1, 24.0);
    final todayPercent = (goal > 0) ? (focusService.todayHours / goal) : 0.0;

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Focus Progress",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularPercentIndicator(
                percent: todayPercent.clamp(0.0, 1.0),
                radius: 70,
                lineWidth: 10,
                progressColor: Colors.black87,
                backgroundColor: Colors.grey.shade300,
                center: Text("${(todayPercent * 100).toStringAsFixed(0)}%",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's focus:",
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  const SizedBox(height: 3),
                  Text("${focusService.todayHours.toStringAsFixed(1)} hrs",
                      style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Goal: ${goal.toStringAsFixed(1)} hrs",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _TasksOverview extends StatelessWidget {
  final HomePageService service;
  const _TasksOverview({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tasks Overview",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            "Stay on top of your daily routine and track your progress.",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, color: Colors.black.withOpacity(0.7)),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TaskStat(value: "${service.completedTasks}", label: "Completed"),
              _TaskStat(
                  value: "${service.totalTasks - service.completedTasks}",
                  label: "Pending"),
              _TaskStat(value: "${service.totalTasks}", label: "Total"),
            ],
          ),
          const SizedBox(height: 20),

          // list
          if (service.tasks.isEmpty)
            Text("No tasks yet. Add some from Task Planner!",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, color: Colors.black.withOpacity(0.6))),
          ...service.tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return CheckboxListTile(
              value: task.completed,
              onChanged: (_) =>
                  context.read<HomePageService>().toggleTask(index),
              title: Text(task.task,
                  style: GoogleFonts.plusJakartaSans(
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  )),
              subtitle: Text(
                  "Duration: ${task.duration.toStringAsFixed(1)} mins",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            );
          }),
        ],
      ),
    );
  }
}

class _JournalHighlight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Journal Highlight",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            "Reflect on your day, note what you're grateful for, and track your mood.",
            style: GoogleFonts.plusJakartaSans(
                color: Colors.black.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => JournalPage()));
              },
              child: const Text("View Journal →"),
            ),
          )
        ],
      ),
    );
  }
}

class _MotivationBlock extends StatelessWidget {
  final String quote;
  const _MotivationBlock({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 40, color: Colors.black87),
          const SizedBox(height: 12),
          Text("Today's Motivation",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            quote.isNotEmpty ? quote : "Stay focused and consistent.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, color: Colors.black.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

// ---------------- Small Widgets ----------------
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w600)),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: Colors.black.withOpacity(0.6))),
      ],
    );
  }
}

class _TaskStat extends StatelessWidget {
  final String value;
  final String label;
  const _TaskStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 26, fontWeight: FontWeight.w600)),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: Colors.black.withOpacity(0.6))),
      ],
    );
  }
}

// ---------------- Loading ----------------
class LoadingScaffold extends StatelessWidget {
  final String message;
  const LoadingScaffold({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}

// ---------------- Decoration ----------------
final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Colors.black26, width: 0.5),
  boxShadow: [
    BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2))
  ],
);
