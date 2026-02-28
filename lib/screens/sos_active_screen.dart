import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_snap/pixel_snap.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/sos_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_service.dart';

class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen> with SingleTickerProviderStateMixin {
  final _sos = SosService();
  final _location = LocationService();
  final _connectivity = ConnectivityService();

  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  StreamSubscription<SosState>? _stateSub;
  StreamSubscription<String>? _locationSub;

  String _address = '';
  String _coords = '';
  bool _isOnline = true;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _address = _location.lastAddress;
    _coords = _location.getCoordinatesString();
    _isOnline = _connectivity.isOnline;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });

    _locationSub = _sos.locationStream.listen((addr) {
      if (mounted) {
        setState(() {
          _address = addr;
          _coords = _location.getCoordinatesString();
        });
      }
    });

    _connectivity.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    _stateSub = _sos.stateStream.listen((state) {
      if (state == SosState.idle && mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _timer?.cancel();
    _stateSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel SOS?'),
        content: const Text('This will stop the emergency alert and location sharing. Are you safe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep SOS Active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("I'm Safe - Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.heavyImpact();
      await _sos.cancelSos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    final contacts = _sos.contacts;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.sosRedDark,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(ps.snap(20), ps.snap(16), ps.snap(20), 0),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SOS ACTIVE',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        letterSpacing: 3,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _fmtDuration(_elapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Courier',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: ps.snap(28)),
                child: Column(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 56),
                    const SizedBox(height: 8),
                    Text(
                      'EMERGENCY ALERT SENT',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your contacts have been notified',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ps.snap(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Chip(
                              icon: _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                              label: _isOnline ? 'Online' : 'Offline',
                              color: _isOnline ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            const _Chip(
                              icon: Icons.location_on_rounded,
                              label: 'Live GPS',
                              color: AppColors.sosRed,
                            ),
                            const SizedBox(width: 10),
                            _Chip(
                              icon: Icons.group_rounded,
                              label: '${contacts.length} notified',
                              color: AppColors.policeBlue,
                            ),
                          ],
                        ),
                        SizedBox(height: ps.snap(20)),
                        _Card(
                          title: 'Your Live Location',
                          icon: Icons.my_location_rounded,
                          iconColor: AppColors.sosRed,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _address.isEmpty ? 'Fetching address...' : _address,
                                style: AppTextStyles.bodyLarge,
                              ),
                              if (_coords.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _coords,
                                  style: AppTextStyles.caption.copyWith(fontFamily: 'Courier', fontSize: 11),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _sos.shareLocation();
                                  },
                                  icon: const Icon(Icons.share_location_rounded, size: 18),
                                  label: const Text('Share Location Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.sosRed,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ps.snap(14)),
                        _Card(
                          title: 'Notified Contacts',
                          icon: Icons.groups_rounded,
                          iconColor: AppColors.policeBlue,
                          child: contacts.isEmpty
                              ? Text(
                            'No contacts were added.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          )
                              : Column(
                            children: contacts
                                .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.sosRed.withOpacity(0.10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        c.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.sosRed,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                        Text(c.phone, style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                ],
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                        SizedBox(height: ps.snap(24)),
                        SizedBox(
                          width: double.infinity,
                          height: ps.snap(58),
                          child: ElevatedButton.icon(
                            onPressed: _cancel,
                            icon: const Icon(Icons.cancel_rounded, size: 22),
                            label: const Text("I'm Safe - Cancel SOS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ps.snap(14)),
                                side: const BorderSide(color: AppColors.border, width: 1.5),
                              ),
                              textStyle: AppTextStyles.buttonLarge,
                            ),
                          ),
                        ),
                        SizedBox(height: ps.snap(12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headlineMedium.copyWith(fontSize: 15)),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}