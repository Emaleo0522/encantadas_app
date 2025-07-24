// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProviderAdapter extends TypeAdapter<Provider> {
  @override
  final int typeId = 4;

  @override
  Provider read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Provider(
      name: fields[0] as String,
      contact: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Provider obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.contact);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
