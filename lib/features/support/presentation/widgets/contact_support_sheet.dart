import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/support/data/faq.dart';
import 'package:bookhaven/features/support/data/support_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showContactSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.palette.surface,
    builder: (_) => const ContactSupportSheet(),
  );
}

class ContactSupportSheet extends ConsumerStatefulWidget {
  const ContactSupportSheet({super.key});

  @override
  ConsumerState<ContactSupportSheet> createState() =>
      _ContactSupportSheetState();
}

class _ContactSupportSheetState extends ConsumerState<ContactSupportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _order = TextEditingController();
  SupportTopic _topic = SupportTopic.order;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(supportRepositoryProvider)
          .submitRequest(
            topic: _topic,
            subject: _subject.text.trim(),
            message: _message.text.trim(),
            orderNumber: _topic == SupportTopic.order
                ? _order.text.trim()
                : null,
          );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Message sent. We will get back to you soon.'),
        ),
      );
    } on SupportException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONTACT SUPPORT',
                style: text.labelMedium?.copyWith(color: c.accent),
              ),
              const SizedBox(height: 4),
              Text(
                'How can we help?',
                style: text.headlineSmall?.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in SupportTopic.values)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: _topic == t,
                      showCheckmark: false,
                      selectedColor: c.primary,
                      backgroundColor: c.surface,
                      side: BorderSide(
                        color: _topic == t ? c.primary : c.border,
                      ),
                      labelStyle: TextStyle(
                        color: _topic == t
                            ? AppColors.onPrimary
                            : c.textPrimary,
                      ),
                      onSelected: _sending
                          ? null
                          : (_) => setState(() => _topic = t),
                    ),
                ],
              ),
              if (_topic == SupportTopic.order) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _order,
                  enabled: !_sending,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Order number (optional)',
                    hintText: 'BH261004-XXXXX',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _subject,
                enabled: !_sending,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length < 3) return 'Please add a short subject';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _message,
                enabled: !_sending,
                maxLength: 1000,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length < 10) {
                    return 'Please tell us a little more (at least 10 characters)';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: text.bodySmall?.copyWith(color: c.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send message'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
