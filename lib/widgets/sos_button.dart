import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/sos_service.dart';

class SosButton extends StatefulWidget {
  final SosState state;
  final VoidCallback onPressed;
  final double size;

  const SosButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.size,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _press;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SosButton old) {
    super.didUpdateWidget(old);
    if (widget.state == SosState.active) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _press.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    HapticFeedback.heavyImpact();
    await _press.forward();
    await _press.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == SosState.active;
    final isActivating = widget.state == SosState.activating;

    return GestureDetector(
      onTap: _tap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _scaleAnim]),
        builder: (_, __) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: SizedBox(
              width: widget.size + 40,
              height: widget.size + 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isActive)
                    Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: widget.size + 24,
                        height: widget.size + 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.sosRed.withOpacity(0.25),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  if (isActive)
                    Container(
                      width: widget.size + 12,
                      height: widget.size + 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sosRed.withOpacity(0.12),
                      ),
                    ),
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.sosRedDark : AppColors.sosRed,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sosRed.withOpacity(0.35),
                          blurRadius: isActive ? 28 : 18,
                          spreadRadius: isActive ? 4 : 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.sosRed.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _content(isActive, isActivating),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(bool isActive, bool isActivating) {
    if (isActivating) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_rounded, color: Colors.white, size: 44),
        const SizedBox(height: 6),
        Text(
          isActive ? 'SOS ACTIVE' : 'SOS',
          style: AppTextStyles.sosLabel.copyWith(fontSize: isActive ? 22 : 28),
        ),
        const SizedBox(height: 2),
        Text(
          isActive ? 'Tap to cancel' : 'Hold for emergency',
          style: AppTextStyles.sosSubLabel,
        ),
      ],
    );
  }
}