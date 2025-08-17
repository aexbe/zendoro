import 'package:hive/hive.dart';

part 'journal_entry_data.g.dart';

@HiveType(typeId: 3)
class JournalEntryData {
  @HiveField(0)
  String content;

  @HiveField(1)
  String grateful;

  @HiveField(2)
  String improvement;

  @HiveField(3)
  String achievement;

  @HiveField(4)
  double mood;

  @HiveField(5)
  double energy;

  JournalEntryData({
    this.content = '',
    this.grateful = '',
    this.improvement = '',
    this.achievement = '',
    this.mood = 5.0,
    this.energy = 5.0,
  });
}
