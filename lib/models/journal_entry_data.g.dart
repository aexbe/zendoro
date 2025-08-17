// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryDataAdapter extends TypeAdapter<JournalEntryData> {
  @override
  final int typeId = 3;

  @override
  JournalEntryData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntryData(
      content: fields[0] as String,
      grateful: fields[1] as String,
      improvement: fields[2] as String,
      achievement: fields[3] as String,
      mood: fields[4] as double,
      energy: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntryData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.grateful)
      ..writeByte(2)
      ..write(obj.improvement)
      ..writeByte(3)
      ..write(obj.achievement)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.energy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
