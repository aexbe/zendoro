// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_entry_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusEntryDataAdapter extends TypeAdapter<FocusEntryData> {
  @override
  final int typeId = 2;

  @override
  FocusEntryData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusEntryData(
      dailyFocus: fields[0] as double,
      dailyFocusGoal: fields[3] as double,
      weeklyFocus: fields[1] as double,
      totalFocus: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, FocusEntryData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dailyFocus)
      ..writeByte(1)
      ..write(obj.weeklyFocus)
      ..writeByte(2)
      ..write(obj.totalFocus)
      ..writeByte(3)
      ..write(obj.dailyFocusGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusEntryDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
