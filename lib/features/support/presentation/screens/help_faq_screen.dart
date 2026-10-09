import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/support/data/faq.dart';
import 'package:bookhaven/features/support/presentation/providers/support_providers.dart';
import 'package:bookhaven/features/support/presentation/widgets/contact_support_sheet.dart';
import 'package:bookhaven/features/support/presentation/widgets/faq_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class HelpFaqScreen extends ConsumerStatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  ConsumerState<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends ConsumerState<HelpFaqScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _category; // null = All

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Faq> _filter(List<Faq> all) {
    final q = _query.trim().toLowerCase();
    return all.where((f) {
      final inCategory = _category == null || f.category == _category;
      final inQuery =
          q.isEmpty ||
          f.question.toLowerCase().contains(q) ||
          f.answer.toLowerCase().contains(q);
      return inCategory && inQuery;
    }).toList();
  }

  Map<String, List<Faq>> _group(List<Faq> list) {
    final map = <String, List<Faq>>{};
    for (final f in list) {
      (map[f.category] ??= []).add(f);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final faqs = ref.watch(faqsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: c.bg,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () async {
          ref.invalidate(faqsProvider);
          await ref.read(faqsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HelpHeader(
                controller: _search,
                hasText: _query.isNotEmpty,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            ...faqs.when(
              loading: () => [_skeleton(c)],
              error: (e, _) => [_errorState(c)],
              data: (all) {
                final categories = _group(all).keys.toList();
                final shown = _filter(all);
                final grouped = _group(shown);
                var index = 0;
                return [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        children: [
                          _chip(
                            c,
                            'All',
                            _category == null,
                            () => setState(() => _category = null),
                          ),
                          for (final cat in categories)
                            _chip(
                              c,
                              cat,
                              _category == cat,
                              () => setState(() => _category = cat),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (shown.isEmpty)
                    SliverToBoxAdapter(child: _emptyState(c))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          for (final entry in grouped.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 10,
                              ),
                              child: Text(
                                entry.key.toUpperCase(),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: c.accent),
                              ),
                            ),
                            for (final f in entry.value)
                              FaqTile(key: ValueKey('faq-${f.id}'), faq: f)
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(
                                      milliseconds: 40 * (index++ % 8),
                                    ),
                                  )
                                  .slideY(begin: 0.05, end: 0),
                          ],
                        ]),
                      ),
                    ),
                ];
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
                child: _ContactCard(
                  onTap: () => showContactSupportSheet(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: c.primary,
        backgroundColor: c.surface,
        side: BorderSide(color: selected ? c.primary : c.border),
        labelStyle: TextStyle(
          color: selected ? AppColors.onPrimary : c.textPrimary,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _skeleton(BuildContext context) {
    final c = context.palette;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverToBoxAdapter(
        child: Shimmer.fromColors(
          baseColor: c.border,
          highlightColor: c.surface,
          child: Column(
            children: List.generate(
              5,
              (_) => Container(
                height: 58,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final c = context.palette;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: c.textSecondary),
            const SizedBox(height: 12),
            Text(
              'We could not load the answers right now.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(faqsProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: c.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No answers match your search.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Try different words, or send us a message below.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(12));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 8,
        20,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.35)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text('SUPPORT', style: text.labelMedium?.copyWith(color: c.accent)),
          const SizedBox(height: 4),
          Text(
            'Help & FAQ',
            style: text.headlineMedium?.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick answers to the questions readers ask most.',
            style: text.bodyMedium?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search help',
              hintStyle: TextStyle(color: c.textSecondary),
              filled: true,
              fillColor: c.surface,
              prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: c.textSecondary),
                      onPressed: onClear,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: const OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_unread_outlined, color: c.accent, size: 28),
          const SizedBox(height: 12),
          Text(
            'Still need help?',
            style: text.titleLarge?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Send us a message and we will get back to you.',
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Contact support'),
            ),
          ),
        ],
      ),
    );
  }
}
