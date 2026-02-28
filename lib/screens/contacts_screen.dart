import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_snap/pixel_snap.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/emergency_contact.dart';
import '../services/sos_service.dart';
import '../widgets/contact_card.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _sos = SosService();

  void _reload() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    final contacts = _sos.contacts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(ps.snap(20), ps.snap(16), ps.snap(20), 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: ps.snap(44),
                      height: ps.snap(44),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Contacts', style: AppTextStyles.headlineLarge),
                      Text('${contacts.length}/3 contacts', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (contacts.isEmpty) _EmptyBanner() else _InfoBanner(contacts: contacts),
            SizedBox(height: ps.snap(8)),
            Expanded(
              child: contacts.isEmpty
                  ? _EmptyState(onAdd: () => _openSheet(context, null))
                  : ListView.builder(
                padding: EdgeInsets.only(top: ps.snap(4), bottom: ps.snap(16)),
                itemCount: contacts.length,
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  return ContactCard(
                    contact: c,
                    onCall: () => _sos.callPolice(number: c.phone),
                    onEdit: () => _openSheet(context, c),
                    onDelete: () => _delete(c),
                    onSetPrimary: () async {
                      await _sos.setPrimaryContact(c.id);
                      _reload();
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(ps.snap(16), ps.snap(8), ps.snap(16), ps.snap(16)),
              child: _sos.canAddContact
                  ? SizedBox(
                width: double.infinity,
                height: ps.snap(56),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openSheet(context, null);
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const Text('Add Emergency Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sosRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ps.snap(14))),
                    textStyle: AppTextStyles.buttonLarge,
                  ),
                ),
              )
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'Maximum 3 contacts reached',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(EmergencyContact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Contact?'),
        content: Text('Remove ${c.name} from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _sos.deleteContact(c.id);
      _reload();
    }
  }

  Future<void> _openSheet(BuildContext context, EmergencyContact? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(
        existing: existing,
        onSave: (contact) async {
          if (existing != null) {
            await _sos.updateContact(contact);
          } else {
            await _sos.addContact(contact);
          }
          _reload();
        },
      ),
    );
  }
}

class _ContactSheet extends StatefulWidget {
  final EmergencyContact? existing;
  final Future<void> Function(EmergencyContact) onSave;

  const _ContactSheet({required this.existing, required this.onSave});

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  bool _saving = false;

  final _relationships = ['Family', 'Spouse', 'Parent', 'Sibling', 'Friend', 'Colleague', 'Neighbor', 'Doctor', 'Other'];
  String _rel = 'Family';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _rel = widget.existing?.relationship ?? 'Family';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final contact = EmergencyContact(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      relationship: _rel,
      isPrimary: widget.existing?.isPrimary ?? false,
    );

    await widget.onSave(contact);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ps = PixelSnap.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(ps.snap(20), ps.snap(8), ps.snap(20), ps.snap(20) + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              widget.existing == null ? 'Add Emergency Contact' : 'Edit Contact',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text('This person will be alerted when you activate SOS', style: AppTextStyles.caption),
            SizedBox(height: ps.snap(24)),
            _Field(
              label: 'Full Name',
              ctrl: _name,
              hint: 'e.g. Ali Hassan',
              icon: Icons.person_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            SizedBox(height: ps.snap(14)),
            _Field(
              label: 'Phone Number',
              ctrl: _phone,
              hint: 'e.g. +92 300 1234567',
              icon: Icons.phone_rounded,
              type: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                if (v.trim().length < 7) return 'Enter a valid phone number';
                return null;
              },
            ),
            SizedBox(height: ps.snap(14)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Relationship', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _rel,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      borderRadius: BorderRadius.circular(12),
                      style: AppTextStyles.bodyLarge,
                      items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _rel = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ps.snap(28)),
            SizedBox(
              width: double.infinity,
              height: ps.snap(56),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.sosRed.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ps.snap(14))),
                  textStyle: AppTextStyles.buttonLarge,
                ),
                child: _saving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
                    : Text(widget.existing == null ? 'Add Contact' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          validator: validator,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sosRed, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sosRed, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.sosRed.withOpacity(0.10), shape: BoxShape.circle),
            child: const Icon(Icons.group_add_rounded, size: 40, color: AppColors.sosRed),
          ),
          const SizedBox(height: 16),
          Text('No Emergency Contacts', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Add up to 3 people who will\nbe alerted during an SOS',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add contacts so they receive your SOS location alert.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final List<EmergencyContact> contacts;
  const _InfoBanner({required this.contacts});

  @override
  Widget build(BuildContext context) {
    final primary = contacts.where((c) => c.isPrimary).map((c) => c.name).firstOrNull;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              primary != null
                  ? '$primary is your primary contact and will be alerted first.'
                  : '${contacts.length} contact${contacts.length > 1 ? 's' : ''} will be alerted during SOS. Tap ⋮ to set a primary.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}