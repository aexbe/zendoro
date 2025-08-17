import 'package:hive/hive.dart';
import 'package:zendoro/models/media_entry_data.dart';
part 'board_model.g.dart';

@HiveType(typeId: 1)
class Board extends HiveObject {
  @HiveField(0)
  String name; // "Vision" or "Dark"

  @HiveField(1)
  List<MediaEntry> entries;

  Board({required this.name, required this.entries});

  void addEntry(MediaEntry entry) {
    entries.add(entry);
    save();
  }

  void removeEntry(MediaEntry entry) {
    entries.remove(entry);
    save();
  }

  List<MediaEntry> getImages() =>
      entries.where((e) => e.isImage()).toList();

  List<MediaEntry> getVideos() =>
      entries.where((e) => e.isVideo()).toList();
}
