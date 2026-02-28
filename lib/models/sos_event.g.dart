// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_event.dart';

class SosEventAdapter extends TypeAdapter<SosEvent> {
  @override
  final int typeId = 1;

  @override
  SosEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SosEvent(
      id: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      timestamp: fields[3] as DateTime,
      sent: fields[4] as bool,
      message: fields[5] as String,
      address: fields[6] as String,
      notifiedContacts: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SosEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.sent)
      ..writeByte(5)
      ..write(obj.message)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.notifiedContacts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SosEventAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}