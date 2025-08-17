// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backlog_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BacklogAdapter extends TypeAdapter<Backlog> {
  @override
  final int typeId = 0;

  @override
  Backlog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Backlog(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      points: fields[3] as int,
      isCompleted: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Backlog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BacklogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
