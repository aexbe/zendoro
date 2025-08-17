import 'package:hive/hive.dart';

part 'focus_entry_data.g.dart';

@HiveType(typeId: 2)
class FocusEntryData {
  @HiveField(0)
  double dailyFocus;

  @HiveField(1)
  double weeklyFocus;

  @HiveField(2)
  double totalFocus;

  @HiveField(3)
  double dailyFocusGoal;

  FocusEntryData({
    this.dailyFocus = 0.0,
    this.dailyFocusGoal = 6.0,
    this.weeklyFocus = 0.0,
    this.totalFocus = 0.0,
  });
}
