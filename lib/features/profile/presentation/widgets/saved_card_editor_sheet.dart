import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/profile/data/saved_card_repository.dart';
import 'package:bookhaven/features/profile/presentation/providers/saved_card_providers.dart';
import 'package:bookhaven/shared/models/saved_card.dart';

/// Returns true when a card was saved.
Future<bool?> showSavedCardEditorSheet(
  BuildContext context, {
  required bool isFirst,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.palette.surface,
    builder: (_) => _SavedCardEditorSheet(isFirst: isFirst),
  );
}

class _SavedCardEditorSheet extends ConsumerStatefulWidget {
  const _SavedCardEditorSheet({required this.isFirst});
  final bool isFirst;

  @override
  ConsumerState<_SavedCardEditorSheet> createState() =>
      _SavedCardEditorSheetState();
}

class _SavedCardEditorSheetState extends ConsumerState<_SavedCardEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _expiry = TextEditingController();

  late bool _makeDefault = widget.isFirst;
  CardBrand _brand = CardBrand.other;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _expiry.dispose();
    super.dispose();
  }

  // ---------- validators ----------

  bool _luhn(String digits) {
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  String? _validateNumber(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter your card number';
    if (digits.length < 13 || digits.length > 19 || !_luhn(digits)) {
      return 'Enter a valid card number';
    }
    return null;
  }

  String? _validateName(String? v) {
    if ((v ?? '').trim().length < 2) return 'Enter the name on the card';
    return null;
  }

  String? _validateExpiry(String? v) {
    final parts = (v ?? '').split('/');
    if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
      return 'Use MM/YY';
    }
    final month = int.tryParse(parts[0]);
    final yy = int.tryParse(parts[1]);
    if (month == null || yy == null || month < 1 || month > 12) {
      return 'Enter a valid expiry';
    }
    final now = DateTime.now();
    final year = 2000 + yy;
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'This card has expired';
    }
    if (year > now.year + 20) return 'Enter a valid expiry';
    return null;
  }

  // ---------- save ----------

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final parts = _expiry.text.split('/');
    final month = int.parse(parts[0]);
    final year = 2000 + int.parse(parts[1]);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(savedCardRepositoryProvider)
          .add(
            cardNumber: _number.text,
            holderName: _name.text,
            expMonth: month,
            expYear: year,
            makeDefault: _makeDefault,
          );
      ref.invalidate(savedCardsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e is PostgrestException && e.code == '23505') {
          _error = 'This card is already saved.';
        } else {
          _error = kDebugMode
              ? '$e'
              : 'We could not save this card. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          4,
          AppDimens.pagePadding,
          AppDimens.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a card', style: t.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Saved cards make checkout quicker.',
                style: t.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppDimens.xl),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [_CardNumberInputFormatter()],
                validator: _validateNumber,
                onChanged: (v) => setState(() => _brand = CardBrand.detect(v)),
                decoration: InputDecoration(
                  labelText: 'Card number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  suffixText: _brand == CardBrand.other ? null : _brand.label,
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _validateName,
                decoration: const InputDecoration(
                  labelText: 'Name on card',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              TextFormField(
                controller: _expiry,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [_ExpiryInputFormatter()],
                validator: _validateExpiry,
                decoration: const InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default card'),
                value: _makeDefault,
                onChanged: widget.isFirst
                    ? null
                    : (v) => setState(() => _makeDefault = v),
              ),
              const SizedBox(height: AppDimens.sm),
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: c.accent),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: Text(
                        'Demo payments only. We keep just the card type, last 4 '
                        'digits and expiry. Your full number and CVV are never saved.',
                        style: t.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppDimens.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                    border: Border.all(color: c.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _error!,
                    style: t.bodySmall?.copyWith(color: c.error),
                  ),
                ),
              ],
              const SizedBox(height: AppDimens.xl),
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
                      : const Text('Save card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 19) digits = digits.substring(0, 19);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
