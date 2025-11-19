// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripSessionAdapter extends TypeAdapter<TripSession> {
  @override
  final int typeId = 1;

  @override
  TripSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripSession(
      carKey: fields[0] as int,
      endTimestamp: fields[1] as DateTime,
      durationInSeconds: fields[2] as int,
      distanceInMeters: fields[3] as double,
      harshBrakingCount: fields[4] as int,
      rapidAccelCount: fields[5] as int,
      sharpTurnCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TripSession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.carKey)
      ..writeByte(1)
      ..write(obj.endTimestamp)
      ..writeByte(2)
      ..write(obj.durationInSeconds)
      ..writeByte(3)
      ..write(obj.distanceInMeters)
      ..writeByte(4)
      ..write(obj.harshBrakingCount)
      ..writeByte(5)
      ..write(obj.rapidAccelCount)
      ..writeByte(6)
      ..write(obj.sharpTurnCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
