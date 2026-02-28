import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/emergency_contact.dart';

class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contact.isPrimary ? AppColors.sosRed.withOpacity(0.35) : AppColors.border,
          width: contact.isPrimary ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Avatar(name: contact.name, isPrimary: contact.isPrimary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                contact.name,
                                style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (contact.isPrimary) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.sosRed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRIMARY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.phone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(contact.relationship, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconBtn(
                        icon: Icons.call_rounded,
                        color: AppColors.success,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onCall();
                        },
                      ),
                      const SizedBox(width: 6),
                      _MoreMenu(
                        contact: contact,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onSetPrimary: onSetPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isPrimary;

  const _Avatar({required this.name, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary ? AppColors.sosRed.withOpacity(0.12) : AppColors.surface,
        border: Border.all(
          color: isPrimary ? AppColors.sosRed : AppColors.border,
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isPrimary ? AppColors.sosRed : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  const _MoreMenu({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surfaceCard,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        if (val == 'edit') onEdit();
        if (val == 'primary') onSetPrimary();
        if (val == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        if (!contact.isPrimary)
          const PopupMenuItem(
            value: 'primary',
            child: Row(children: [
              Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 10),
              Text('Set as Primary'),
            ]),
          ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_rounded, color: AppColors.info, size: 18),
            SizedBox(width: 10),
            Text('Edit'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_rounded, color: AppColors.sosRed, size: 18),
            const SizedBox(width: 10),
            Text('Remove', style: TextStyle(color: AppColors.sosRed)),
          ]),
        ),
      ],
    );
  }
}