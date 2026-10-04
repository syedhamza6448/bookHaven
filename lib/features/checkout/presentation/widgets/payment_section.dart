import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/input_formatters.dart';
import 'package:bookhaven/core/utils/validators.dart';
import 'package:bookhaven/features/checkout/presentation/providers/checkout_controller.dart';

class PaymentSection extends StatelessWidget {
  const PaymentSection({
    super.key,
    required this.method,
    required this.onChanged,
    required this.formKey,
    required this.nameCtrl,
    required this.numberCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
  });

  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onChanged;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController numberCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Option(
          icon: Icons.payments_outlined,
          title: 'Cash on delivery',
          subtitle: 'Pay when your books arrive',
          selected: method == PaymentMethod.cod,
          onTap: () => onChanged(PaymentMethod.cod),
        ),
        _Option(
          icon: Icons.credit_card_outlined,
          title: 'Credit / debit card',
          subtitle: 'Demo payment, no real charge',
          selected: method == PaymentMethod.card,
          onTap: () => onChanged(PaymentMethod.card),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: method == PaymentMethod.card
              ? Form(
                  key: formKey,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppDimens.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              Validators.required(v, 'Name on card'),
                          decoration: const InputDecoration(
                            labelText: 'Name on card',
                          ),
                        ),
                        const SizedBox(height: AppDimens.md),
                        TextFormField(
                          controller: numberCtrl, // keep your existing controller name
                          keyboardType: TextInputType.number,
                          inputFormatters: [CardNumberFormatter()],
                          validator: Validators.cardNumber,
                          decoration: const InputDecoration(
                            labelText: 'Card number',
                            hintText: '1234 5678 9012 3456',
                          ),
                        ),
                        const SizedBox(height: AppDimens.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: expiryCtrl,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [ExpiryFormatter()],
                                validator: Validators.cardExpiry,
                                decoration: const InputDecoration(
                                  labelText: 'Expiry',
                                  hintText: 'MM/YY',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimens.md),
                            Expanded(
                              child: TextFormField(
                                controller: cvvCtrl,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: Validators.cardCvv,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.sm),
                        Text(
                          'This is a simulated payment. Nothing is charged, and only the last 4 digits are saved with your order.',
                          style: text.bodySmall?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? c.primary : c.textSecondary),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? c.primary : c.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
