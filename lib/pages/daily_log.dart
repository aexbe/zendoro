// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import '../../models/user_model.dart';
import '../../models/journal_entry_data.dart';

class JournalService extends ChangeNotifier {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  final TextEditingController contentController = TextEditingController();
  final TextEditingController gratefulController = TextEditingController();
  final TextEditingController improvementController = TextEditingController();
  final TextEditingController achievementController = TextEditingController();
  double moodRating = 5.0;
  double energyRating = 5.0;

  UserModel? currentUser;

  JournalService() {
    _loadUser();
  }

  int _dateKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  Future<void> _loadUser() async {
    final userBox = Hive.box<UserModel>('userBox');
    currentUser = userBox.get('currentUser');
    isLoading = false;
    notifyListeners();
  }

  JournalEntryData? get entryForSelected {
    final key = _dateKey(selectedDate);
    return currentUser?.journalEntries?[key];
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void prepareEdit() {
    final entry = entryForSelected;
    contentController.text = entry?.content ?? '';
    gratefulController.text = entry?.grateful ?? '';
    improvementController.text = entry?.improvement ?? '';
    achievementController.text = entry?.achievement ?? '';
    moodRating = entry?.mood ?? 5.0;
    energyRating = entry?.energy ?? 5.0;
  }

  Future<void> saveEntry() async {
    if (currentUser == null) return;

    final key = _dateKey(selectedDate);
    currentUser!.journalEntries ??= {};
    currentUser!.journalEntries![key] = JournalEntryData(
      content: contentController.text,
      grateful: gratefulController.text,
      improvement: improvementController.text,
      achievement: achievementController.text,
      mood: moodRating,
      energy: energyRating,
    );

    final userBox = Hive.box<UserModel>('userBox');
    final usersBox = Hive.box<UserModel>('usersBox');

    await userBox.put('currentUser', currentUser!);
    if (currentUser!.email.isNotEmpty) {
      await usersBox.put(currentUser!.email, currentUser!);
    }

    notifyListeners();
  }
}

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JournalService(),
      child: const _JournalView(),
    );
  }
}

class _JournalView extends StatelessWidget {
  const _JournalView();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JournalService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Journal',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar Section
                Container(
                  margin: const EdgeInsets.all(12),
                  width: MediaQuery.of(context).size.width - 30,
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
                  child: TableCalendar(
                    firstDay:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: service.selectedDate,
                    selectedDayPredicate: (day) =>
                        isSameDay(day, service.selectedDate),
                    onDaySelected: (selectedDay, _) {
                      service.selectDate(selectedDay);
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black87,
                      ),
                      todayTextStyle: TextStyle(color: Colors.white),
                      selectedDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final hasEntry =
                            service.currentUser?.journalEntries?.containsKey(
                                  service._dateKey(day),
                                ) ??
                                false;

                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasEntry
                                ? Colors.black.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: isSameDay(day, service.selectedDate)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Entry Details
                Expanded(
                  child: service.entryForSelected == null
                      ? const Center(
                          child: Text(
                            'No entry for this date',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        )
                      : _EntryDetails(entry: service.entryForSelected!),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          service.prepareEdit();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => ChangeNotifierProvider.value(
              value: service,
              child: const _EditEntrySheet(),
            ),
          );
        },
        backgroundColor: Colors.black87,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

class _EntryDetails extends StatefulWidget {
  final JournalEntryData entry;
  const _EntryDetails({required this.entry});

  @override
  State<_EntryDetails> createState() => _EntryDetailsState();
}

class _EntryDetailsState extends State<_EntryDetails> {
  Widget _buildCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      width: MediaQuery.of(context).size.width - 30,
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
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          content.isEmpty ? "—" : content,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildCard("Mood:", widget.entry.mood.toStringAsFixed(1),
            Icons.sentiment_satisfied),
        _buildCard(
            "Energy:", widget.entry.energy.toStringAsFixed(1), Icons.bolt),
        _buildCard("Grateful:", widget.entry.grateful, Icons.favorite),
        _buildCard("Improvement:", widget.entry.improvement, Icons.trending_up),
        _buildCard(
            "Achievement:", widget.entry.achievement, Icons.emoji_events),
        _buildCard("Notes:", widget.entry.content, Icons.notes),
      ],
    );
  }
}

class _EditEntrySheet extends StatelessWidget {
  const _EditEntrySheet();

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        maxLines: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JournalService>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text("Edit Journal",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(service.contentController, "Type any note..."),
            _buildTextField(
                service.gratefulController, "I was/am grateful for..."),
            _buildTextField(
                service.improvementController, "I did improvemetn in..."),
            _buildTextField(service.achievementController, "I achieved..."),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  "Mood",
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: Slider(
                    value: service.moodRating,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: service.moodRating.toStringAsFixed(1),
                    onChanged: (v) {
                      service.moodRating = v;
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      service.notifyListeners();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  "Energy",
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: Slider(
                    value: service.energyRating,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: service.energyRating.toStringAsFixed(1),
                    onChanged: (v) {
                      service.energyRating = v;
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      service.notifyListeners();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                service.saveEntry();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
