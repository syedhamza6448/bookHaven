import 'dart:typed_data';

import 'package:bookhaven/features/catalog/presentation/providers/book_details_providers.dart';
import 'package:bookhaven/features/home/presentation/providers/home_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/admin/data/admin_book_form.dart';
import 'package:bookhaven/features/admin/data/admin_books_repository.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_book_form_providers.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_books_controller.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_dashboard_providers.dart';

// Add these via the quick fix (Ctrl + .) on each red name below:
// bestsellersProvider, newArrivalsProvider, featuredBookProvider,
// genresProvider, bookDetailsProvider

class BookFormScreen extends ConsumerWidget {
  const BookFormScreen({super.key, this.bookId});

  /// null = add a new book, otherwise edit this book.
  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = bookId;
    if (id == null) return const _BookForm(initial: null);

    final async = ref.watch(adminBookFormProvider(id));
    return async.when(
      data: (book) => _BookForm(initial: book),
      loading: () => _Shell(
        title: 'Edit book',
        child: Center(
          child: CircularProgressIndicator(color: context.palette.accent),
        ),
      ),
      error: (e, _) => _Shell(
        title: 'Edit book',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(height: AppDimens.md),
                Text(
                  e is AdminActionException
                      ? e.message
                      : 'Could not load this book.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                const SizedBox(height: AppDimens.lg),
                OutlinedButton(
                  onPressed: () => ref.invalidate(adminBookFormProvider(id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.3)!],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.sm,
                  AppDimens.sm,
                  AppDimens.pagePadding,
                  AppDimens.xl,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: onPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppDimens.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADMIN',
                            style: text.labelMedium?.copyWith(color: c.accent),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: text.headlineMedium?.copyWith(
                              color: onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BookForm extends ConsumerStatefulWidget {
  const _BookForm({required this.initial});
  final BookFormData? initial;

  @override
  ConsumerState<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends ConsumerState<_BookForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _originalPrice;
  late final TextEditingController _stock;

  String _author = '';
  String? _genreId;
  bool _featured = false;
  DateTime? _published;

  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  bool _removeCover = false;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    _title = TextEditingController(text: b?.title ?? '');
    _description = TextEditingController(text: b?.description ?? '');
    _price = TextEditingController(
      text: b == null ? '' : b.price.toStringAsFixed(2),
    );
    _originalPrice = TextEditingController(
      text: b?.originalPrice == null
          ? ''
          : b!.originalPrice!.toStringAsFixed(2),
    );
    _stock = TextEditingController(text: b == null ? '' : b.stock.toString());
    _author = b?.authorName ?? '';
    _genreId = b?.genreId;
    _featured = b?.isFeatured ?? false;
    _published = b?.publishedAt ?? (b == null ? DateTime.now() : null);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _originalPrice.dispose();
    _stock.dispose();
    super.dispose();
  }

  InputDecoration _dec(
    String label, {
    String? hint,
    String? helper,
    String? prefix,
  }) {
    final c = context.palette;
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusInput),
          borderSide: BorderSide(color: color, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      prefixText: prefix,
      labelStyle: TextStyle(color: c.textSecondary),
      hintStyle: TextStyle(color: c.textSecondary),
      filled: true,
      fillColor: c.surface,
      enabledBorder: border(c.border),
      focusedBorder: border(c.primary, 1.4),
      errorBorder: border(c.error),
      focusedErrorBorder: border(c.error, 1.4),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickCover() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      _snack('That image is too large (max 5 MB)');
      return;
    }
    final name = file.name.toLowerCase();
    final ext = name.endsWith('.png')
        ? 'png'
        : name.endsWith('.webp')
        ? 'webp'
        : 'jpg';
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
      _removeCover = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _published ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _published = picked);
  }

  void _refreshCatalog() {
    ref.read(adminBooksControllerProvider.notifier).refresh(silent: true);
    ref.invalidate(adminDashboardProvider);
    ref.invalidate(bestsellersProvider);
    ref.invalidate(newArrivalsProvider);
    ref.invalidate(featuredBookProvider);
    ref.invalidate(genresProvider);
    ref.invalidate(bookDetailsProvider);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(adminBookEditorRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final oldCover = widget.initial?.coverUrl;

    setState(() => _saving = true);
    String? uploaded;
    try {
      String? coverUrl = _removeCover ? null : oldCover;
      if (_pickedBytes != null) {
        uploaded = await repo.uploadCover(_pickedBytes!, _pickedExt);
        coverUrl = uploaded;
      }

      await repo.saveBook(
        id: widget.initial?.id,
        title: _title.text.trim(),
        authorName: _author.trim(),
        genreId: _genreId!,
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        originalPrice: _originalPrice.text.trim().isEmpty
            ? null
            : double.parse(_originalPrice.text.trim()),
        stock: int.parse(_stock.text.trim()),
        isFeatured: _featured,
        coverUrl: coverUrl,
        publishedAt: _published,
      );

      if (oldCover != null && oldCover != coverUrl) {
        await repo.removeCoverFile(oldCover);
      }

      _refreshCatalog();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Book updated' : 'Book added')),
        );
      if (mounted) context.pop();
    } catch (e) {
      if (uploaded != null) await repo.removeCoverFile(uploaded);
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        e is AdminActionException
            ? e.message
            : 'Could not save the book. Try again.',
      );
    }
  }

  Widget _coverPreview(BuildContext context) {
    final c = context.palette;
    final placeholder = Container(
      color: c.border,
      alignment: Alignment.center,
      child: Icon(Icons.menu_book_outlined, color: c.textSecondary, size: 36),
    );

    Widget image;
    final url = widget.initial?.coverUrl;
    if (_pickedBytes != null) {
      image = Image.memory(_pickedBytes!, fit: BoxFit.cover);
    } else if (!_removeCover && url != null && url.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    } else {
      image = placeholder;
    }

    return Container(
      width: 120,
      height: 176,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final authors =
        ref.watch(adminAuthorNamesProvider).value ?? const <String>[];
    final genres =
        ref.watch(adminGenreOptionsProvider).value ?? const <GenreOption>[];

    final hasCover =
        _pickedBytes != null ||
        (!_removeCover && (widget.initial?.coverUrl?.isNotEmpty ?? false));
    final isNewAuthor =
        _author.trim().isNotEmpty &&
        !authors.any((a) => a.toLowerCase() == _author.trim().toLowerCase());

    return _Shell(
      title: _isEdit ? 'Edit book' : 'Add a book',
      child: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.pagePadding,
                  AppDimens.xl,
                  AppDimens.pagePadding,
                  AppDimens.xl,
                ),
                children: [
                  Center(child: _coverPreview(context)),
                  const SizedBox(height: AppDimens.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _saving ? null : _pickCover,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(hasCover ? 'Change cover' : 'Choose cover'),
                      ),
                      if (hasCover)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  _pickedBytes = null;
                                  _removeCover = true;
                                }),
                          child: Text(
                            'Remove',
                            style: TextStyle(color: c.error),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.lg),

                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 150,
                    style: TextStyle(color: c.textPrimary),
                    decoration: _dec('Title').copyWith(counterText: ''),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter the book title'
                        : null,
                  ),
                  const SizedBox(height: AppDimens.lg),

                  LayoutBuilder(
                    builder: (context, box) => Autocomplete<String>(
                      initialValue: TextEditingValue(text: _author),
                      optionsBuilder: (value) {
                        final q = value.text.trim().toLowerCase();
                        if (q.isEmpty) return const Iterable<String>.empty();
                        return authors
                            .where((a) => a.toLowerCase().contains(q))
                            .take(6);
                      },
                      onSelected: (s) => setState(() => _author = s),
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmit) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(color: c.textPrimary),
                              onChanged: (v) => setState(() => _author = v),
                              decoration: _dec(
                                'Author',
                                helper: isNewAuthor
                                    ? 'New author — will be created when you save'
                                    : 'Pick an existing author or type a new one',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter or choose an author'
                                  : null,
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            color: c.surface,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusInput,
                            ),
                            child: SizedBox(
                              width: box.maxWidth,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: [
                                  for (final o in options)
                                    ListTile(
                                      dense: true,
                                      title: Text(
                                        o,
                                        style: TextStyle(color: c.textPrimary),
                                      ),
                                      onTap: () => onSelected(o),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),

                  DropdownButtonFormField<String>(
                    value: genres.any((g) => g.id == _genreId)
                        ? _genreId
                        : null,
                    isExpanded: true,
                    dropdownColor: c.surface,
                    style: TextStyle(color: c.textPrimary, fontSize: 16),
                    decoration: _dec('Genre'),
                    items: [
                      for (final g in genres)
                        DropdownMenuItem(value: g.id, child: Text(g.name)),
                    ],
                    onChanged: (v) => setState(() => _genreId = v),
                    validator: (v) => v == null ? 'Choose a genre' : null,
                  ),
                  const SizedBox(height: AppDimens.lg),

                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: c.textPrimary),
                    decoration: _dec('Description'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Add a short description'
                        : null,
                  ),
                  const SizedBox(height: AppDimens.lg),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          style: TextStyle(color: c.textPrimary),
                          decoration: _dec('Price', prefix: '\$ '),
                          validator: (v) {
                            final n = double.tryParse((v ?? '').trim());
                            if (n == null || n <= 0)
                              return 'Enter a valid price';
                            if (n > 9999) return 'Too high';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: TextFormField(
                          controller: _originalPrice,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          style: TextStyle(color: c.textPrimary),
                          decoration: _dec('Original price', prefix: '\$ '),
                          validator: (v) {
                            final raw = (v ?? '').trim();
                            if (raw.isEmpty) return null;
                            final n = double.tryParse(raw);
                            final price = double.tryParse(_price.text.trim());
                            if (n == null) return 'Invalid';
                            if (price != null && n <= price)
                              return 'Must exceed price';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Add an original price to show the book as discounted.',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),

                  TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: c.textPrimary),
                    decoration: _dec('Stock (copies available)'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null) return 'Enter the stock count';
                      if (n > 100000) return 'Too high';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.lg),

                  InkWell(
                    borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                    onTap: _saving ? null : _pickDate,
                    child: InputDecorator(
                      decoration: _dec('Published on').copyWith(
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: c.textSecondary,
                        ),
                      ),
                      child: Text(
                        _published == null
                            ? 'Not set'
                            : DateFormat('d MMM yyyy').format(_published!),
                        style: TextStyle(color: c.textPrimary, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),

                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusInput,
                      ),
                      border: Border.all(color: c.border),
                    ),
                    child: SwitchListTile(
                      value: _featured,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _featured = v),
                      activeColor: c.primary,
                      title: Text(
                        'Feature on Home',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Only one book is featured at a time.',
                        style: TextStyle(color: c.textSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.md,
              AppDimens.pagePadding,
              AppDimens.md + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: onPrimary,
                        ),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Add book'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
