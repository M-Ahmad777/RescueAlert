import 'package:hive/hive.dart';

part 'sos_event.g.dart';

@HiveType(typeId: 1)
class SosEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  bool sent;

  @HiveField(5)
  String message;

  @HiveField(6)
  String address;

  @HiveField(7)
  List<String> notifiedContacts;

  SosEvent({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.sent = false,
    this.message = '',
    this.address = '',
    this.notifiedContacts = const [],
  });

  String get mapsUrl => 'https://maps.google.com/?q=$latitude,$longitude';

  String get shareText =>
      '🚨 SOS ALERT!\n\n'
          'I need emergency help!\n\n'
          '📍 Location: $address\n'
          '🗺️ Maps: $mapsUrl\n\n'
          '⏰ Time: ${_formatTime(timestamp)}\n\n'
          'Please call emergency services immediately!';

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s - ${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'sent': sent,
    'message': message,
    'address': address,
    'notifiedContacts': notifiedContacts,
  };
}