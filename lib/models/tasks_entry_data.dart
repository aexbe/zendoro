import 'package:hive/hive.dart';

part 'tasks_entry_data.g.dart';

@HiveType(typeId: 6)
class TasksEntryData {
  @HiveField(0)
  String task;

  @HiveField(1)
  bool completed;

  @HiveField(2)
  double duration;

  TasksEntryData({
    this.task = " ",
    this.completed = false,
    this.duration = 0.0,
  });
}
