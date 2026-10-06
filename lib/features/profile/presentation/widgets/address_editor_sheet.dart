import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/profile/data/address_manage_repository.dart';
import 'package:bookhaven/features/profile/data/address_repository.dart';
import 'package:bookhaven/features/profile/presentation/providers/address_providers.dart';
import 'package:bookhaven/shared/models/address.dart';

/// Returns true when an address was saved.
Future<bool?> showAddressEditorSheet(
  BuildContext context, {
  Address? existing,
  bool isFirst = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusCard + 8),
      ),
    ),
    builder: (_) => _AddressEditorSheet(existing: existing, isFirst: isFirst),
  );
}

class _AddressEditorSheet extends ConsumerStatefulWidget {
  const _AddressEditorSheet({this.existing, required this.isFirst});

  final Address? existing;
  final bool isFirst;

  @override
  ConsumerState<_AddressEditorSheet> createState() =>
      _AddressEditorSheetState();
}

class _AddressEditorSheetState extends ConsumerState<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;
  late final TextEditingController _country;

  late bool _isDefault;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;
  bool get _lockedDefault =>
      widget.isFirst || (widget.existing?.isDefault ?? false);

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? '');
    _name = TextEditingController(text: a?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _line2 = TextEditingController(text: a?.line2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _state = TextEditingController(text: a?.state ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _country = TextEditingController(text: a?.country ?? '');
    _isDefault = _lockedDefault;
  }

  @override
  void dispose() {
    for (final c in [
      _label,
      _name,
      _phone,
      _line1,
      _line2,
      _city,
      _state,
      _postal,
      _country,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? 'Please enter $what' : null;

  String? _phoneValidator(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(addressRepositoryProvider)
          .saveAddress(
            id: widget.existing?.id,
            label: _label.text,
            fullName: _name.text,
            phone: _phone.text,
            line1: _line1.text,
            line2: _line2.text,
            city: _city.text,
            state: _state.text,
            postalCode: _postal.text,
            country: _country.text,
            isDefault: _isDefault,
          );
      ref.invalidate(addressesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = kDebugMode
            ? '$e'
            : 'We could not save this address. Please try again.';
      });
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.words,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      textInputAction: action,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const gap = SizedBox(height: AppDimens.md);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          0,
          AppDimens.pagePadding,
          AppDimens.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DELIVERY DETAILS',
                style: t.labelMedium?.copyWith(color: c.accent),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                _isEdit ? 'Edit address' : 'New address',
                style: t.headlineSmall,
              ),
              const SizedBox(height: AppDimens.lg),
              _field(
                _label,
                'Label (e.g. Home, Office)',
                validator: (v) => _required(v, 'a label'),
              ),
              const SizedBox(height: AppDimens.sm),
              Wrap(
                spacing: AppDimens.sm,
                children: [
                  for (final l in const ['Home', 'Work', 'Other'])
                    ChoiceChip(
                      label: Text(l),
                      selected:
                          _label.text.trim().toLowerCase() == l.toLowerCase(),
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _label.text = l),
                    ),
                ],
              ),
              gap,
              _field(
                _name,
                'Full name',
                validator: (v) => _required(v, 'the recipient name'),
              ),
              gap,
              _field(
                _phone,
                'Phone number',
                validator: _phoneValidator,
                keyboardType: TextInputType.phone,
                capitalization: TextCapitalization.none,
              ),
              gap,
              _field(
                _line1,
                'Address line 1',
                validator: (v) => _required(v, 'your street address'),
              ),
              gap,
              _field(_line2, 'Address line 2 (optional)'),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      _city,
                      'City',
                      validator: (v) => _required(v, 'a city'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: _field(
                      _state,
                      'State / Province',
                      validator: (v) => _required(v, 'a state'),
                    ),
                  ),
                ],
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      _postal,
                      'Postal code',
                      validator: (v) => _required(v, 'a postal code'),
                      capitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: _field(
                      _country,
                      'Country',
                      validator: (v) => _required(v, 'a country'),
                      action: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default address'),
                subtitle: _lockedDefault
                    ? const Text('This is your default address')
                    : null,
                value: _isDefault,
                onChanged: (_saving || _lockedDefault)
                    ? null
                    : (v) => setState(() => _isDefault = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppDimens.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                    border: Border.all(color: c.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!, style: TextStyle(color: c.error)),
                ),
              ],
              const SizedBox(height: AppDimens.lg),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
