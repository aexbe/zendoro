
import 'dart:typed_data';
import 'package:hive/hive.dart';
part 'media_entry_data.g.dart';

@HiveType(typeId: 4)
enum MediaType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  text,
}

@HiveType(typeId: 5)
class MediaEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  MediaType type;

  @HiveField(2)
  Uint8List? rawBytes; // store media as bytes

  @HiveField(3)
  String? description;

  MediaEntry({
    required this.id,
    required this.type,
    required this.rawBytes,
    this.description,
  });

  bool isImage() => type == MediaType.image;
  bool isVideo() => type == MediaType.video;
  bool isAudio() => type == MediaType.audio;
  bool isText() => type == MediaType.text;
}
