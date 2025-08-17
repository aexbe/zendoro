import 'package:hive/hive.dart';

part 'backlog_model.g.dart';

@HiveType(typeId: 0)
class Backlog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  int points;

  @HiveField(4)
  bool isCompleted;

  Backlog({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    this.isCompleted = false,
  });

  void markCompleted() {
    isCompleted = true;
    save();
  }

  void addPoints(int extra) {
    points += extra;
    save();
  }
}
