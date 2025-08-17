import 'package:hive/hive.dart';
import 'package:zendoro/models/focus_entry_data.dart';
import 'package:zendoro/models/tasks_entry_data.dart';
import 'journal_entry_data.dart';

part 'user_model.g.dart';

@HiveType(typeId: 7)
class UserModel {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password;

  @HiveField(3)
  List<int>? profilePicBytes; // raw bytes

  @HiveField(4)
  String gender;

  @HiveField(5)
  int age;

  @HiveField(6)
  Map<int, JournalEntryData>? journalEntries; // yyyyMMdd → JournalEntryData

  @HiveField(7)
  List<TasksEntryData>? tasks;

  @HiveField(8)
  Map<int, FocusEntryData>? focusEntries; // keys: yyyyMMdd as int

  @HiveField(9)
  double? totalFocusAccumulated;


  UserModel({
    required this.name,
    required this.email,
    required this.password,
    this.profilePicBytes,
    required this.gender,
    required this.age,
    Map<int, JournalEntryData>? journalEntries,
    List<TasksEntryData>? task,
    Map<int, FocusEntryData>? focusEntries,
    this.totalFocusAccumulated,
  })  : journalEntries = journalEntries ?? {}, focusEntries = focusEntries ?? {};
  // -----------------------
  // Helper methods (optional, convenient)
  // -----------------------
  List<TasksEntryData> getTasksList() => tasks ?? [];

  void addTask(TasksEntryData t) {
    tasks ??= [];
    tasks!.add(t);
  }

  void updateTaskAt(int index, TasksEntryData t) {
    if (tasks == null) return;
    if (index < 0 || index >= tasks!.length) return;
    tasks![index] = t;
  }

  void removeTaskAt(int index) {
    if (tasks == null) return;
    if (index < 0 || index >= tasks!.length) return;
    tasks!.removeAt(index);
  }
}
