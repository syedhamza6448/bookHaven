import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/validators.dart';
import 'package:bookhaven/features/profile/data/address_repository.dart';
import 'package:bookhaven/shared/models/address.dart';

Future<Address?> showAddressFormSheet(
  BuildContext context, {
  bool isFirst = false,
}) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddressFormSheet(isFirst: isFirst),
  );
}

class AddressFormSheet extends ConsumerStatefulWidget {
  const AddressFormSheet({super.key, this.isFirst = false});
  final bool isFirst;

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'Pakistan');
  String _label = 'Home';
  late bool _isDefault = widget.isFirst;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    _name = TextEditingController(
      text: (meta?['full_name'] ?? meta?['name'] ?? '') as String,
    );
  }

  @override
  void dispose() {
    for (final c in [
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(addressRepositoryProvider)
          .add(
            label: _label,
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            line1: _line1.text.trim(),
            line2: _line2.text,
            city: _city.text.trim(),
            state: _state.text,
            postalCode: _postal.text.trim(),
            country: _country.text.trim(),
            isDefault: _isDefault,
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save the address. Please try again.';
        });
      }
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        textCapitalization: caps,
        textInputAction: TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New address',
                style: text.headlineSmall?.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppDimens.lg),
              Wrap(
                spacing: AppDimens.sm,
                children: [
                  for (final l in const ['Home', 'Work', 'Other'])
                    ChoiceChip(
                      label: Text(l),
                      selected: _label == l,
                      onSelected: (_) => setState(() => _label = l),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),
              _field(
                _name,
                'Full name',
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              _field(
                _phone,
                'Phone number',
                validator: Validators.phone,
                keyboard: TextInputType.phone,
              ),
              _field(
                _line1,
                'Address line 1',
                validator: (v) => Validators.required(v, 'Address'),
              ),
              _field(_line2, 'Address line 2 (optional)'),
              _field(
                _city,
                'City',
                validator: (v) => Validators.required(v, 'City'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(_state, 'State / Province')),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: _field(
                      _postal,
                      'Postal code',
                      validator: (v) => Validators.required(v, 'Postal code'),
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _field(
                _country,
                'Country',
                validator: (v) => Validators.required(v, 'Country'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Make this my default address'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.md),
                  child: Text(
                    _error!,
                    style: text.bodySmall?.copyWith(color: c.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
