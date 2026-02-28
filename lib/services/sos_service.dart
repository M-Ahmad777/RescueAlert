import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_contact.dart';
import '../models/sos_event.dart';
import 'location_service.dart';
import 'connectivity_service.dart';

enum SosState { idle, activating, active, cancelling }

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  final _location = LocationService();
  final _connectivity = ConnectivityService();
  final _uuid = const Uuid();

  SosState _state = SosState.idle;
  SosEvent? _activeSos;
  Timer? _updateTimer;

  late Box<EmergencyContact> _contactsBox;
  late Box<SosEvent> _queueBox;

  final _stateCtrl = StreamController<SosState>.broadcast();
  final _locationCtrl = StreamController<String>.broadcast();

  SosState get state => _state;
  SosEvent? get activeSos => _activeSos;
  Stream<SosState> get stateStream => _stateCtrl.stream;
  Stream<String> get locationStream => _locationCtrl.stream;
  List<EmergencyContact> get contacts => _contactsBox.values.toList();
  bool get canAddContact => _contactsBox.length < 3;
  int get pendingOfflineCount => _queueBox.values.where((e) => !e.sent).length;

  Future<void> initialize() async {
    _contactsBox = await Hive.openBox<EmergencyContact>('emergency_contacts');
    _queueBox = await Hive.openBox<SosEvent>('sos_queue');
    _connectivity.onConnectivityChanged.listen((online) {
      if (online) _drainQueue();
    });
  }

  Future<bool> activateSos() async {
    if (_state != SosState.idle) return false;
    _setState(SosState.activating);

    try {
      final pos = await _location.getCurrentPosition();
      final event = SosEvent(
        id: _uuid.v4(),
        latitude: pos?.latitude ?? 0.0,
        longitude: pos?.longitude ?? 0.0,
        timestamp: DateTime.now(),
        address: _location.lastAddress,
        message: 'EMERGENCY SOS',
        notifiedContacts: contacts.map((c) => c.phone).toList(),
      );

      _activeSos = event;
      _setState(SosState.active);
      await _queueBox.put(event.id, event);
      _startUpdates();
      await _sendAlerts(event);
      return true;
    } catch (_) {
      _setState(SosState.idle);
      return false;
    }
  }

  Future<void> cancelSos() async {
    if (_state != SosState.active) return;
    _setState(SosState.cancelling);
    _stopUpdates();
    _activeSos = null;
    await Future.delayed(const Duration(milliseconds: 500));
    _setState(SosState.idle);
  }

  Future<void> _sendAlerts(SosEvent event) async {
    if (_connectivity.isOnline) {
      await _saveToFirestore(event);
      await _shareLocation(event);
      event.sent = true;
      await event.save();
    } else {
      event.sent = false;
      await event.save();
    }
  }

  Future<void> _saveToFirestore(SosEvent event) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('sos_events').doc(event.id).set({
        ...event.toMap(),
        'userId': user?.uid ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> shareLocation() async {
    if (_activeSos == null) return;
    await _shareLocation(_activeSos!);
  }

  Future<void> _shareLocation(SosEvent event) async {
    try {
      final list = _contactsBox.values.toList();
      if (list.isEmpty) {
        await Share.share(event.shareText, subject: '🚨 EMERGENCY SOS ALERT');
        return;
      }

      final primary = list.firstWhere((c) => c.isPrimary, orElse: () => list.first);
      final phone = primary.phone.replaceAll(RegExp(r'[^\d+]'), '');
      final msg = Uri.encodeComponent(event.shareText);
      final waUrl = Uri.parse('whatsapp://send?phone=$phone&text=$msg');

      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl);
      } else {
        final smsUrl = Uri.parse('sms:$phone?body=$msg');
        if (await canLaunchUrl(smsUrl)) {
          await launchUrl(smsUrl);
        } else {
          await Share.share(event.shareText, subject: '🚨 EMERGENCY SOS ALERT');
        }
      }
    } catch (_) {
      await Share.share(event.shareText, subject: '🚨 EMERGENCY SOS ALERT');
    }
  }

  Future<void> callPolice({String number = '15'}) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _startUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_activeSos == null) return;
      final pos = await _location.getCurrentPosition();
      if (pos != null) {
        _activeSos!.latitude = pos.latitude;
        _activeSos!.longitude = pos.longitude;
        _activeSos!.address = _location.lastAddress;
        await _activeSos!.save();
        _locationCtrl.add(_location.lastAddress);
        if (_connectivity.isOnline) await _saveToFirestore(_activeSos!);
      }
    });
  }

  void _stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _drainQueue() async {
    final unsent = _queueBox.values.where((e) => !e.sent).toList();
    for (final event in unsent) {
      await _saveToFirestore(event);
      event.sent = true;
      await event.save();
    }
  }

  Future<void> addContact(EmergencyContact contact) async {
    if (_contactsBox.length >= 3) return;
    await _contactsBox.put(contact.id, contact);
  }

  Future<void> updateContact(EmergencyContact contact) async {
    await _contactsBox.put(contact.id, contact);
  }

  Future<void> deleteContact(String id) async {
    await _contactsBox.delete(id);
  }

  Future<void> setPrimaryContact(String id) async {
    for (final c in _contactsBox.values) {
      c.isPrimary = c.id == id;
      await c.save();
    }
  }

  void _setState(SosState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void dispose() {
    _stateCtrl.close();
    _locationCtrl.close();
    _stopUpdates();
  }
}