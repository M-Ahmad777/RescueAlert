import 'package:hive/hive.dart';

part 'emergency_contact.g.dart';

@HiveType(typeId: 0)
class EmergencyContact extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String relationship;

  @HiveField(4)
  bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'isPrimary': isPrimary,
  };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) => EmergencyContact(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    relationship: map['relationship'] ?? '',
    isPrimary: map['isPrimary'] ?? false,
  );
}