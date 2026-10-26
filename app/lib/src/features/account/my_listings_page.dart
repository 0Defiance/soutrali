import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/motifs.dart';
import '../../theme/soutrali_theme.dart';
import '../account/account_repository.dart';
import '../auth/auth_repository.dart';
import '../discover/category_icons.dart';
import '../discover/listings_repository.dart';
import '../discover/references_repository.dart';

/// « Mes annonces » : consultation, modification et clôture (F-05).
class MyListingsPage extends ConsumerStatefulWidget {
  const MyListingsPage({super.key});

  @override
  ConsumerState<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends ConsumerState<MyListingsPage> {
  bool _redirecting = false;

  void _requireAuth(AuthUser? user) {
    if (user == null && !_redirecting) {
      _redirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login?from=${Uri.encodeComponent('/mes-annonces')}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.value;
    _requireAuth(user);

    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      appBar: AppBar(
        backgroundColor: SoutraliColors.deepGreen,
        foregroundColor: Colors.white,
        title: const Text('Mes annonces'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: InteractiveMotif(
        style: MotifStyle.light,
        density: 44,
        opacity: 0.6,
        child: user == null
          ? const Center(child: CircularProgressIndicator())
          : ref.watch(myListingsProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Impossible de charger vos annonces.'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(myListingsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (listings) => listings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.campaign_outlined, size: 42, color: SoutraliColors.muted),
                              const SizedBox(height: 12),
                              const Text('Vous n’avez pas encore publié d’annonce.'),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: SoutraliColors.orange),
                                onPressed: () => context.go('/'),
                                icon: const Icon(Icons.add),
                                label: const Text('Publier une annonce'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: listings.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => HoverLift(
                          rise: 4,
                          child: _MyListingCard(
                          listing: listings[index],
                          onEdit: () => _edit(listings[index]),
                          onPublish: listings[index].status == 'BROUILLON' && listings[index].publishAt != null
                              ? () => _publishNow(listings[index])
                              : null,
                          onClose: listings[index].status == 'PUBLIEE'
                              ? () => _close(listings[index])
                              : null,
                          ),
                        ),
                      ),
              ),
      ),
    );
  }

  Future<void> _edit(MyListing listing) async {
    final draft = await showDialog<ListingDraft>(
      context: context,
      builder: (dialogContext) => _EditListingDialog(listing: listing),
    );

    if (draft == null) return;

    try {
      await ref.read(accountRepositoryProvider).update(listing.id, draft);
      ref.invalidate(myListingsProvider);
      ref.invalidate(listingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce mise à jour.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }

  Future<void> _publishNow(MyListing listing) async {
    try {
      await ref.read(accountRepositoryProvider).publishNow(listing.id);
      ref.invalidate(myListingsProvider);
      ref.invalidate(listingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce mise en ligne immédiatement.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }

  Future<void> _close(MyListing listing) async {
    final outcome = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CloseListingDialog(),
    );

    if (outcome == null) return;

    try {
      await ref.read(accountRepositoryProvider).close(listing.id, outcome: outcome);
      ref.invalidate(myListingsProvider);
      ref.invalidate(listingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce clôturée.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({
    required this.listing,
    required this.onEdit,
    this.onPublish,
    this.onClose,
  });

  final MyListing listing;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isProgrammed = listing.status == 'BROUILLON' && listing.publishAt != null;
    final statusColor = switch (listing.status) {
      'PUBLIEE' => SoutraliColors.paleGreen,
      'CLOTUREE' => const Color(0xFFEDEDED),
      'MASQUEE' => SoutraliColors.paleOrange,
      'BROUILLON' => isProgrammed ? SoutraliColors.paleOrange : Colors.white,
      _ => Colors.white,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  border: Border.all(color: SoutraliColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isProgrammed ? 'Programmée' : _statusLabel(listing.status),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                listing.type == 'DEMANDE' ? 'Demande' : 'Offre',
                style: const TextStyle(color: SoutraliColors.muted),
              ),
              const SizedBox(width: 8),
              Text(
                listing.nature == 'BENEVOLE' ? '· Bénévole' : '· Rémunérée',
                style: const TextStyle(color: SoutraliColors.muted),
              ),
              const Spacer(),
              if (listing.createdAt != null)
                Text(
                  DateFormat('d MMM yyyy', 'fr').format(listing.createdAt!),
                  style: const TextStyle(color: SoutraliColors.muted, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(categoryIcon(listing.categoryIcon), size: 15, color: SoutraliColors.green),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${listing.categoryName} · ${listing.communeName}'
                  '${listing.status == 'CLOTUREE' && listing.closureOutcome != null ? ' · Issue : ${_outcomeLabel(listing.closureOutcome!)}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SoutraliColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
          if (isProgrammed && listing.publishAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Publication le ${DateFormat('d MMM yyyy à HH:mm', 'fr').format(listing.publishAt!)}',
              style: const TextStyle(color: SoutraliColors.muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier'),
              ),
              if (onPublish != null) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SoutraliColors.orange,
                    foregroundColor: SoutraliColors.ink,
                    minimumSize: const Size(44, 40),
                  ),
                  onPressed: onPublish,
                  icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                  label: const Text('Publier maintenant'),
                ),
              ],
              if (onClose != null) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SoutraliColors.green,
                    minimumSize: const Size(44, 40),
                  ),
                  onPressed: onClose,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Clôturer'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'PUBLIEE' => 'Publiée',
        'CLOTUREE' => 'Clôturée',
        'MASQUEE' => 'Masquée',
        'EN_REVUE' => 'En revue',
        'REFUSEE' => 'Refusée',
        _ => 'Brouillon',
      };

  String _outcomeLabel(String outcome) => switch (outcome) {
        'BESOIN_SATISFAIT' => 'besoin satisfait',
        'SOLUTION_TROUVEE' => 'solution trouvée',
        'AUTRE' => 'autre raison',
        _ => outcome.toLowerCase(),
      };
}

class _EditListingDialog extends ConsumerStatefulWidget {
  const _EditListingDialog({required this.listing});

  final MyListing listing;

  @override
  ConsumerState<_EditListingDialog> createState() => _EditListingDialogState();
}

class _EditListingDialogState extends ConsumerState<_EditListingDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _availability;
  late String _type;
  late String _nature;
  late int _categoryId;
  late int _communeId;
  DateTime? _publishAt;
  bool _scheduleChanged = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.listing.title);
    _description = TextEditingController(text: widget.listing.description);
    _availability = TextEditingController(text: widget.listing.availability ?? '');
    _type = widget.listing.type;
    _nature = widget.listing.nature;
    _categoryId = widget.listing.categoryId;
    _communeId = widget.listing.communeId;
    _publishAt = widget.listing.publishAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _availability.dispose();
    super.dispose();
  }

  Future<void> _pickPublishAt() async {
    final now = DateTime.now();
    final hasFutureSchedule = _publishAt != null && _publishAt!.isAfter(now);

    final date = await showDatePicker(
      context: context,
      initialDate: hasFutureSchedule ? _publishAt! : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(hasFutureSchedule ? _publishAt! : now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() {
      _publishAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _scheduleChanged = true;
    });
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final description = _description.text.trim();

    if (title.length < 4 || description.length < 10) {
      setState(() => _error = 'Titre (4 caractères min.) et description (10 caractères min.) obligatoires.');
      return;
    }

    if (_scheduleChanged && (_publishAt == null || !_publishAt!.isAfter(DateTime.now()))) {
      setState(() => _error = 'Choisissez une date et une heure futures pour la publication.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    Navigator.pop(
      context,
      ListingDraft(
        title: title,
        description: description,
        type: _type,
        nature: _nature,
        categoryId: _categoryId,
        communeId: _communeId,
        availability: _availability.text,
        publishAt: _scheduleChanged ? _publishAt : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <ReferenceItem>[];
    final communes = ref.watch(communesProvider).value ?? const <ReferenceItem>[];

    return AlertDialog(
      title: const Text('Modifier l’annonce'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _title.text,
                maxLength: 140,
                decoration: const InputDecoration(labelText: 'Titre'),
                onChanged: (value) => _title.text = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _description.text,
                minLines: 3,
                maxLines: 5,
                maxLength: 5000,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                onChanged: (value) => _description.text = value,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'DEMANDE', child: Text('Demande')),
                  DropdownMenuItem(value: 'OFFRE', child: Text('Offre')),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _nature,
                decoration: const InputDecoration(labelText: 'Nature'),
                items: const [
                  DropdownMenuItem(value: 'BENEVOLE', child: Text('Bénévole')),
                  DropdownMenuItem(value: 'REMUNEREE', child: Text('Rémunérée')),
                ],
                onChanged: (value) => setState(() => _nature = value ?? _nature),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [
                  for (final item in categories)
                    DropdownMenuItem(
                      value: item.id,
                      child: Row(
                        children: [
                          Icon(categoryIcon(item.icon), size: 18, color: SoutraliColors.green),
                          const SizedBox(width: 8),
                          Flexible(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value ?? _categoryId),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _communeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Commune'),
                items: [
                  for (final item in communes) DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (value) => setState(() => _communeId = value ?? _communeId),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _availability.text,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Disponibilité (facultatif)'),
                onChanged: (value) => _availability.text = value,
              ),
              if (widget.listing.status == 'BROUILLON') ...[
                const SizedBox(height: 14),
                const Text('Publication programmée', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _publishAt == null
                            ? 'Aucune date : annonce en attente de mise en ligne.'
                            : DateFormat('d MMMM yyyy à HH:mm', 'fr').format(_publishAt!),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _pickPublishAt,
                      child: Text(_publishAt == null ? 'Programmer' : 'Modifier'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'La date n’est modifiable qu’avant la mise en ligne (« Publier maintenant » la déclenche telle quelle).',
                  style: TextStyle(color: SoutraliColors.muted, fontSize: 13),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SoutraliColors.green,
            minimumSize: const Size(44, 44),
          ),
          onPressed: _saving ? null : _submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _CloseListingDialog extends StatefulWidget {
  const _CloseListingDialog();

  @override
  State<_CloseListingDialog> createState() => _CloseListingDialogState();
}

class _CloseListingDialogState extends State<_CloseListingDialog> {
  String _choice = 'BESOIN_SATISFAIT';
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.check_circle_outline, color: SoutraliColors.green),
      title: const Text('Clôturer cette annonce'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Indiquez l’issue : l’annonce ne sera plus visible dans les résultats.'),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _choice,
              onChanged: (value) => setState(() => _choice = value ?? _choice),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'BESOIN_SATISFAIT',
                    dense: true,
                    title: const Text('Besoin satisfait'),
                  ),
                  RadioListTile<String>(
                    value: 'SOLUTION_TROUVEE',
                    dense: true,
                    title: const Text('Solution trouvée ailleurs'),
                  ),
                  RadioListTile<String>(
                    value: 'AUTRE',
                    dense: true,
                    title: const Text('Autre raison'),
                  ),
                ],
              ),
            ),
            if (_choice == 'AUTRE')
              TextField(
                controller: _otherController,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Raison (24 caractères max.)'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SoutraliColors.green,
            minimumSize: const Size(44, 44),
          ),
          onPressed: () {
            final outcome = _choice == 'AUTRE'
                ? (_otherController.text.trim().isEmpty ? 'AUTRE' : _otherController.text.trim())
                : _choice;
            Navigator.pop(context, outcome);
          },
          child: const Text('Clôturer'),
        ),
      ],
    );
  }
}
