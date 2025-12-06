// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CarAdapter extends TypeAdapter<Car> {
  @override
  final int typeId = 0;

  @override
  Car read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Car(
      plateNumber: fields[0] as String,
      model: fields[1] as String,
      brand: fields[2] as String,
      currentMileage: fields[3] as double,
      tireSize: fields[4] as String?,
      engine: fields[5] as String?,
      lastService: fields[6] as String?,
      oilType: fields[7] as String?,
      oilLifeRemaining: fields[8] as double,
      engineCapacity: fields[9] as String?,
      transmissionType: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Car obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.plateNumber)
      ..writeByte(1)
      ..write(obj.model)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.currentMileage)
      ..writeByte(4)
      ..write(obj.tireSize)
      ..writeByte(5)
      ..write(obj.engine)
      ..writeByte(6)
      ..write(obj.lastService)
      ..writeByte(7)
      ..write(obj.oilType)
      ..writeByte(8)
      ..write(obj.oilLifeRemaining)
      ..writeByte(9)
      ..write(obj.engineCapacity)
      ..writeByte(10)
      ..write(obj.transmissionType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
