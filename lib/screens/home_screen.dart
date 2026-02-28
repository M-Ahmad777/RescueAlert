import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_snap/pixel_snap.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/sos_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/sos_button.dart';
import '../widgets/police_dial_sheet.dart';
import 'sos_active_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sos = SosService();
  final _location = LocationService();
  final _connectivity = ConnectivityService();

  StreamSubscription<SosState>? _stateSub;
  String _address = 'Fetching location...';
  String _coords = '';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _init();
    _stateSub = _sos.stateStream.listen((state) {
      if (state == SosState.active && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosActiveScreen()));
      }
    });
  }

  Future<void> _init() async {
    await _location.requestPermission();
    setState(() => _isOnline = _connectivity.isOnline);
    _connectivity.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    final pos = await _location.getCurrentPosition();
    if (mounted && pos != null) {
      setState(() {
        _address = _location.lastAddress;
        _coords = _location.getCoordinatesString();
      });
    }

    await _location.startTracking(
      onPosition: (_) {},
      onAddress: (addr) {
        if (mounted) {
          setState(() {
            _address = addr;
            _coords = _location.getCoordinatesString();
          });
        }
      },
    );
  }

  Future<void> _handleSos() async {
    if (_sos.contacts.isEmpty) {
      _noContactsDialog();
      return;
    }
    final ok = await _confirmDialog();
    if (!ok) return;
    HapticFeedback.heavyImpact();
    final success = await _sos.activateSos();
    if (!success && mounted) _showError('Failed to activate SOS. Check location permissions.');
  }

  Future<bool> _confirmDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sosRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: AppColors.sosRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Activate SOS?'),
          ],
        ),
        content: const Text(
          'This will immediately:\n\n'
              '• Share your live GPS location\n'
              '• Alert all emergency contacts\n'
              '• Start location tracking\n\n'
              'Only use in a real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ACTIVATE SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _noContactsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No Contacts Added'),
        content: const Text('Please add at least one emergency contact before activating SOS.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add Contact', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.sosRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    final w = MediaQuery.of(context).size.width;
    final btnSize = ps.snap(w * 0.70).clamp(220.0, 300.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              isOnline: _isOnline,
              pendingCount: _sos.pendingOfflineCount,
              onContactsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              ),
            ),
            _LocationBar(address: _address, coords: _coords),
            Expanded(
              child: StreamBuilder<SosState>(
                stream: _sos.stateStream,
                initialData: _sos.state,
                builder: (_, snapshot) {
                  final state = snapshot.data ?? SosState.idle;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedOpacity(
                          opacity: state == SosState.idle ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            'TAP IN EMERGENCY',
                            style: AppTextStyles.labelLarge.copyWith(
                              letterSpacing: 3,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        SizedBox(height: ps.snap(20)),
                        SosButton(state: state, onPressed: _handleSos, size: btnSize),
                        SizedBox(height: ps.snap(32)),
                        _ContactsBadge(count: _sos.contacts.length),
                      ],
                    ),
                  );
                },
              ),
            ),
            _PoliceBar(onTap: () => PoliceDialSheet.show(context)),
            SizedBox(height: ps.snap(8)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback onContactsTap;

  const _TopBar({required this.isOnline, required this.pendingCount, required this.onContactsTap});

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(ps.snap(20), ps.snap(16), ps.snap(20), ps.snap(8)),
      child: Row(
        children: [
          Container(
            width: ps.snap(36),
            height: ps.snap(36),
            decoration: BoxDecoration(
              color: AppColors.sosRed,
              borderRadius: BorderRadius.circular(ps.snap(10)),
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RescueAlert', style: AppTextStyles.headlineMedium),
              Text(
                isOnline ? 'Online' : (pendingCount > 0 ? '$pendingCount alert(s) queued' : 'Offline'),
                style: AppTextStyles.caption.copyWith(
                  color: isOnline ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: ps.snap(8),
            height: ps.snap(8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.warning,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onContactsTap();
            },
            child: Container(
              width: ps.snap(44),
              height: ps.snap(44),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.contacts_rounded, color: AppColors.textPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final String address;
  final String coords;

  const _LocationBar({required this.address, required this.coords});

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ps.snap(16), vertical: ps.snap(6)),
      padding: EdgeInsets.all(ps.snap(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.sosRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (coords.isNotEmpty) Text(coords, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _ContactsBadge extends StatelessWidget {
  final int count;
  const _ContactsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final color = count == 0 ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            count == 0 ? 'No emergency contacts' : '$count emergency contact${count > 1 ? 's' : ''} ready',
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PoliceBar extends StatelessWidget {
  final VoidCallback onTap;
  const _PoliceBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ps.snap(16), vertical: ps.snap(8)),
      child: SizedBox(
        width: double.infinity,
        height: ps.snap(56),
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          icon: const Icon(Icons.local_police_rounded, size: 22),
          label: const Text('Call Emergency Services  (15 • 1122 • 115)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.policeBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ps.snap(14))),
            textStyle: AppTextStyles.buttonMedium,
          ),
        ),
      ),
    );
  }
}