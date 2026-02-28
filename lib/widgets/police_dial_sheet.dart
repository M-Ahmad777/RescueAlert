import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/sos_service.dart';

class PoliceDialSheet extends StatelessWidget {
  final _sos = SosService();

  PoliceDialSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PoliceDialSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Emergency Services', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Pakistan Emergency Numbers',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _DialBtn(
            label: 'Pakistan Police',
            number: '15',
            subtitle: 'National Emergency',
            icon: Icons.local_police_rounded,
            color: AppColors.policeBlue,
            onTap: () async {
              HapticFeedback.heavyImpact();
              await _sos.callPolice(number: '15');
            },
          ),
          const SizedBox(height: 12),
          _DialBtn(
            label: 'Rescue 1122',
            number: '1122',
            subtitle: 'Ambulance & Fire',
            icon: Icons.emergency_rounded,
            color: AppColors.sosRed,
            onTap: () async {
              HapticFeedback.heavyImpact();
              await _sos.callPolice(number: '1122');
            },
          ),
          const SizedBox(height: 12),
          _DialBtn(
            label: 'Edhi Foundation',
            number: '115',
            subtitle: 'Ambulance Service',
            icon: Icons.medical_services_rounded,
            color: AppColors.success,
            onTap: () async {
              HapticFeedback.heavyImpact();
              await _sos.callPolice(number: '115');
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Close',
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialBtn extends StatelessWidget {
  final String label;
  final String number;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DialBtn({
    required this.label,
    required this.number,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.headlineMedium),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}