// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 7;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      name: fields[0] as String,
      email: fields[1] as String,
      password: fields[2] as String,
      profilePicBytes: (fields[3] as List?)?.cast<int>(),
      gender: fields[4] as String,
      age: fields[5] as int,
      journalEntries: (fields[6] as Map?)?.cast<int, JournalEntryData>(),
      focusEntries: (fields[8] as Map?)?.cast<int, FocusEntryData>(),
      totalFocusAccumulated: fields[9] as double?,
    )..tasks = (fields[7] as List?)?.cast<TasksEntryData>();
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.profilePicBytes)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.age)
      ..writeByte(6)
      ..write(obj.journalEntries)
      ..writeByte(7)
      ..write(obj.tasks)
      ..writeByte(8)
      ..write(obj.focusEntries)
      ..writeByte(9)
      ..write(obj.totalFocusAccumulated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
