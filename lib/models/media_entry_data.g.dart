// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_entry_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaEntryAdapter extends TypeAdapter<MediaEntry> {
  @override
  final int typeId = 5;

  @override
  MediaEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaEntry(
      id: fields[0] as String,
      type: fields[1] as MediaType,
      rawBytes: fields[2] as Uint8List?,
      description: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.rawBytes)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaTypeAdapter extends TypeAdapter<MediaType> {
  @override
  final int typeId = 4;

  @override
  MediaType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MediaType.image;
      case 1:
        return MediaType.video;
      case 2:
        return MediaType.audio;
      case 3:
        return MediaType.text;
      default:
        return MediaType.image;
    }
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    switch (obj) {
      case MediaType.image:
        writer.writeByte(0);
        break;
      case MediaType.video:
        writer.writeByte(1);
        break;
      case MediaType.audio:
        writer.writeByte(2);
        break;
      case MediaType.text:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
