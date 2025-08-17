// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_entry_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TasksEntryDataAdapter extends TypeAdapter<TasksEntryData> {
  @override
  final int typeId = 6;

  @override
  TasksEntryData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TasksEntryData(
      task: fields[0] as String,
      completed: fields[1] as bool,
      duration: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TasksEntryData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.task)
      ..writeByte(1)
      ..write(obj.completed)
      ..writeByte(2)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasksEntryDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
