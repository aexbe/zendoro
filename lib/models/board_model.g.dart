// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoardAdapter extends TypeAdapter<Board> {
  @override
  final int typeId = 1;

  @override
  Board read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Board(
      name: fields[0] as String,
      entries: (fields[1] as List).cast<MediaEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, Board obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.entries);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
