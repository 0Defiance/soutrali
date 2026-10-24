import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/soutrali_theme.dart';
import '../account/account_repository.dart';
import '../account/contact_channels_section.dart';
import '../account/profile_safety_section.dart';
import '../auth/auth_repository.dart';
import '../messaging/messaging_repository.dart';
import 'listing.dart';
import 'listings_repository.dart';
import 'references_repository.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _resultsHeadingKey = GlobalKey();
  String _commune = '';
  String _type = '';
  String _nature = '';
  String _categoryId = '';

  ListingFilters get _filters => ListingFilters(
        query: _searchController.text,
        commune: _commune,
        type: _type,
        nature: _nature,
        category: int.tryParse(_categoryId),
      );

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final columns = width >= 1180 ? 3 : width >= 760 ? 2 : 1;
    final results = ref.watch(listingsProvider(_filters));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(compact)),
            SliverToBoxAdapter(child: _buildIntro(compact)),
            SliverToBoxAdapter(child: _buildMainActions(compact)),
            SliverToBoxAdapter(child: _buildSearch(compact)),
            SliverToBoxAdapter(child: _buildSectionHeading()),
            results.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: _buildError(error),
              ),
              data: (listings) => listings.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 8, compact ? 16 : 40, 48),
                      sliver: SliverGrid.builder(
                        itemCount: listings.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 246,
                        ),
                        itemBuilder: (context, index) => _ListingCard(listing: listings[index]),
                      ),
                    ),
            ),
            SliverToBoxAdapter(child: _buildFooter(compact)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SoutraliColors.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 40, vertical: 12),
      child: Row(
        children: [
          Image.asset('assets/brand/soutrali-logo.png', width: compact ? 132 : 158, height: 52, fit: BoxFit.contain),
          const Spacer(),
          if (!compact) ...[
            const Icon(Icons.location_on_outlined, color: SoutraliColors.green, size: 18),
            const SizedBox(width: 4),
            const Text('Abidjan', style: TextStyle(color: SoutraliColors.muted)),
            const SizedBox(width: 12),
          ],
          _buildAccountActions(context, compact: compact),
        ],
      ),
    );
  }

  /// Actions du compte : visiteur → connexion / inscription ; connecté →
  /// menu (annonces, messagerie avec compteur de non-lus, profil, déconnexion).
  Widget _buildAccountActions(BuildContext context, {required bool compact}) {
    final auth = ref.watch(authProvider);
    final user = auth.value;
    final unread = ref.watch(conversationsProvider).value?.unreadTotal ?? 0;

    if (auth.isLoading && !auth.hasValue) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (user == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Connexion'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SoutraliColors.orange,
              foregroundColor: SoutraliColors.ink,
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => context.go('/register'),
            child: const Text('S’inscrire'),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Menu du compte',
      onSelected: (value) {
        switch (value) {
          case 'annonces':
            context.go('/mes-annonces');
          case 'messagerie':
            context.go('/messagerie');
          case 'profil':
            _showProfileDialog();
          case 'deconnexion':
            _signOut();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'annonces',
          child: Row(children: [Icon(Icons.campaign_outlined, size: 20), SizedBox(width: 10), Text('Mes annonces')]),
        ),
        PopupMenuItem(
          value: 'messagerie',
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 10),
              const Text('Messagerie'),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: SoutraliColors.orange,
                  child: Text(
                    '$unread',
                    style: const TextStyle(fontSize: 11, color: SoutraliColors.ink),
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'profil',
          child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 10), Text('Mon profil')]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'deconnexion',
          child: Row(children: [Icon(Icons.logout, size: 20), SizedBox(width: 10), Text('Se déconnecter')]),
        ),
      ],
      child: CircleAvatar(
        radius: 19,
        backgroundColor: SoutraliColors.green,
        child: Text(
          user.initials,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {
      ref.read(authProvider.notifier).resetLocally();
    }

    ref.invalidate(conversationsProvider);
    ref.invalidate(myListingsProvider);
    ref.invalidate(myReportsProvider);

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _showLoginPrompt() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: SoutraliColors.orange),
        title: const Text('Connectez-vous pour publier'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const Text(
            'La publication demande un compte gratuit (e-mail + mot de passe). '
            'Vous pourrez ensuite gérer vos annonces, contacter les auteurs et suivre vos signalements.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/register');
            },
            child: const Text('Créer un compte'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SoutraliColors.green,
              minimumSize: const Size(44, 44),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/login');
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileDialog() async {
    final user = ref.read(authProvider).value;
    final reportsFuture = user == null ? null : ref.read(myReportsProvider.future);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.person_outline, color: SoutraliColors.green),
        title: Text(user == null ? 'Votre profil Soutrali' : 'Compte de ${user.displayName}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: user == null
              ? const Text(
                  'Créez un compte pour publier vos annonces, contacter les auteurs, '
                  'suivre vos messages et vos signalements.',
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileLine('Nom', user.displayName),
                      _profileLine('E-mail', user.email),
                      _profileLine('Commune', user.communeName ?? '—'),
                      _profileLine('Rôle', user.role ?? 'UTILISATEUR'),
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text(
                        'Mes signalements',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: FutureBuilder(
                          future: reportsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final reports = snapshot.data ?? const [];
                            if (reports.isEmpty) {
                              return const Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Aucun signalement émis.',
                                  style: TextStyle(color: SoutraliColors.muted),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final report = reports[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.flag_outlined, size: 18, color: SoutraliColors.orange),
                                  title: Text(report.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    '${report.listingTitle} · ${_reportStatusLabel(report.status)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const ContactChannelsSection(),
                      const SizedBox(height: 12),
                      const Divider(),
                      const BlockedAccountsSection(),
                    ],
                  ),
                ),
        ),
        actions: [
          if (user == null) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/register');
              },
              child: const Text('Créer un compte'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: SoutraliColors.green),
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/login');
              },
              child: const Text('Se connecter'),
            ),
          ] else
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _signOut();
              },
              child: const Text('Se déconnecter'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _profileLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _reportStatusLabel(String status) => switch (status) {
        'NOUVEAU' => 'enregistré',
        'EN_EXAMEN' => 'en cours d’examen',
        'TRAITE' => 'traité',
        'REJETE' => 'classé sans suite',
        _ => status.toLowerCase(),
      };

  Future<void> _showPublicationChoices({required bool isRequest}) async {
    final color = isRequest ? SoutraliColors.orange : SoutraliColors.green;
    final choices = isRequest
        ? const [
            _PublicationChoice(
              title: 'Service spontané / immédiat',
              subtitle: 'J’ai un besoin à résoudre dès que possible.',
              icon: Icons.bolt_outlined,
              kind: 'immediate',
            ),
            _PublicationChoice(
              title: 'Service programmé',
              subtitle: 'Je souhaite planifier mon besoin à une date ou période.',
              icon: Icons.calendar_month_outlined,
              kind: 'scheduled',
            ),
          ]
        : const [
            _PublicationChoice(
              title: 'Répondre à un besoin',
              subtitle: 'Consulter les demandes et proposer mon aide.',
              icon: Icons.reply_outlined,
              kind: 'response',
            ),
            _PublicationChoice(
              title: 'Proposer mes services de manière programmée',
              subtitle: 'Décrire mes services et mes disponibilités.',
              icon: Icons.event_available_outlined,
              kind: 'scheduled',
            ),
          ];

    final selected = await showDialog<_PublicationChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRequest ? 'Faire une annonce' : 'Proposer mes services'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < choices.length; index++) ...[
                _ChoiceTile(
                  choice: choices[index],
                  color: color,
                  onTap: () => Navigator.pop(context, choices[index]),
                ),
                if (index < choices.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );

    if (selected == null || !mounted) return;
    if (selected.kind == 'response') {
      setState(() {
        _type = 'DEMANDE';
        _nature = '';
        _searchController.clear();
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final headingContext = _resultsHeadingKey.currentContext;
      if (headingContext != null && headingContext.mounted) {
        await Scrollable.ensureVisible(
          headingContext,
          duration: const Duration(milliseconds: 250),
          alignment: 0.05,
        );
      }
      return;
    }

    await _showPublicationDraft(isRequest: isRequest, choice: selected, color: color);
  }

  Future<void> _showPublicationDraft({
    required bool isRequest,
    required _PublicationChoice choice,
    required Color color,
  }) async {
    if (ref.read(authProvider).value == null) {
      await _showLoginPrompt();
      return;
    }

    List<ReferenceItem> categories;
    List<ReferenceItem> communes;
    try {
      categories = await ref.read(categoriesProvider.future);
      communes = await ref.read(communesProvider.future);
    } catch (_) {
      categories = const <ReferenceItem>[];
      communes = const <ReferenceItem>[];
    }

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final availabilityController = TextEditingController();
    final budgetController = TextEditingController();
    final isScheduled = choice.kind == 'scheduled';
    final dialogTitle = isRequest
        ? (isScheduled ? 'Planifier un besoin' : 'Décrire votre besoin')
        : (isScheduled ? 'Décrire mes disponibilités' : 'Répondre à un besoin');

    var categoryId = '';
    var communeId = ref.read(authProvider).value?.communeId?.toString() ?? '';
    var nature = 'BENEVOLE';
    var submitting = false;
    var errorMessage = '';
    DateTime? publishAt;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleController,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: isRequest ? 'Quel est votre besoin ?' : 'Quel service proposez-vous ?',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Ce champ est obligatoire.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Ajoutez quelques précisions.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categories.any((item) => item.id.toString() == categoryId) ? categoryId : '',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Catégorie *'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('— Choisir —')),
                        for (final item in categories)
                          DropdownMenuItem(value: item.id.toString(), child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (value) => setDialogState(() => categoryId = value ?? ''),
                      validator: (value) => (value == null || value.isEmpty) ? 'Catégorie obligatoire.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: communes.any((item) => item.id.toString() == communeId) ? communeId : '',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Commune *'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('— Choisir —')),
                        for (final item in communes)
                          DropdownMenuItem(value: item.id.toString(), child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (value) => setDialogState(() => communeId = value ?? ''),
                      validator: (value) => (value == null || value.isEmpty) ? 'Commune obligatoire.' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Nature *', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Bénévole'),
                          selected: nature == 'BENEVOLE',
                          onSelected: (_) => setDialogState(() => nature = 'BENEVOLE'),
                        ),
                        ChoiceChip(
                          label: const Text('Rémunérée'),
                          selected: nature == 'REMUNEREE',
                          onSelected: (_) => setDialogState(() => nature = 'REMUNEREE'),
                        ),
                      ],
                    ),
                    if (nature == 'REMUNEREE') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        decoration: const InputDecoration(
                          labelText: 'Budget indicatif en FCFA (facultatif)',
                          hintText: 'Ex. 5000',
                        ),
                      ),
                    ],
                    if (isScheduled) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: availabilityController,
                        maxLength: 160,
                        decoration: InputDecoration(
                          labelText: isRequest ? 'Date ou période souhaitée' : 'Mes jours et horaires disponibles',
                          hintText: isRequest ? 'Ex. semaine du 10 novembre' : 'Ex. lundi et mercredi après 16 h',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Précisez une date ou vos disponibilités.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('Publication de l’annonce', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              publishAt == null
                                  ? 'Publiée immédiatement après validation.'
                                  : 'Programmée le ${DateFormat('d MMMM yyyy à HH:mm', 'fr').format(publishAt!)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: now,
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 365)),
                              );
                              if (date == null || !dialogContext.mounted) return;
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
                              );
                              if (time == null) return;
                              setDialogState(() {
                                publishAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                              });
                            },
                            child: Text(publishAt == null ? 'Programmer' : 'Modifier'),
                          ),
                          if (publishAt != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Publier immédiatement',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setDialogState(() => publishAt = null),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (categories.isEmpty || communes.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Référentiels indisponibles : fermez cette fenêtre et réessayez.',
                        style: TextStyle(color: SoutraliColors.orangeText, fontSize: 13),
                      ),
                    ],
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(errorMessage, style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: isRequest ? SoutraliColors.ink : Colors.white,
                minimumSize: const Size(44, 44),
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;

                      if (publishAt != null && !publishAt!.isAfter(DateTime.now())) {
                        setDialogState(() {
                          errorMessage = 'Choisissez une date et une heure futures pour la publication.';
                        });
                        return;
                      }

                      setDialogState(() {
                        submitting = true;
                        errorMessage = '';
                      });

                      try {
                        await ref.read(accountRepositoryProvider).create(
                              ListingDraft(
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                type: isRequest ? 'DEMANDE' : 'OFFRE',
                                nature: nature,
                                categoryId: int.parse(categoryId),
                                communeId: int.parse(communeId),
                                availability: isScheduled ? availabilityController.text.trim() : null,
                                budget: nature == 'REMUNEREE' ? double.tryParse(budgetController.text.trim()) : null,
                                publishAt: isScheduled ? publishAt : null,
                              ),
                            );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ref.invalidate(listingsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isScheduled && publishAt != null
                                    ? 'Annonce programmée : publiée le '
                                        '${DateFormat('d MMMM yyyy à HH:mm', 'fr').format(publishAt!)}.'
                                    : 'Annonce publiée : visible immédiatement.',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        setDialogState(() {
                          submitting = false;
                          errorMessage = apiErrorMessage(error);
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publier l’annonce'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
    availabilityController.dispose();
    budgetController.dispose();
  }

  Widget _buildIntro(bool compact) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: SoutraliColors.paleGreen,
        border: Border(bottom: BorderSide(color: SoutraliColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(24, compact ? 34 : 52, 24, compact ? 32 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow(label: 'ABIDJAN · ENTRAIDE DE PROXIMITÉ'),
                    const SizedBox(height: 14),
                    Text(
                      'Un coup de main\nprès de chez vous.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: compact ? 34 : 48),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 510),
                      child: Text(
                        'Trouvez une aide, proposez vos compétences et faites vivre l’entraide dans votre commune.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _searchFocusNode.requestFocus,
                      icon: const Icon(Icons.search),
                      label: const Text('Explorer les annonces'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SoutraliColors.orange,
                        foregroundColor: SoutraliColors.ink,
                        minimumSize: const Size(44, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 270),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _ValueLine(icon: Icons.handshake_outlined, title: 'Un réseau de proximité', detail: 'Des demandes et des offres à l’échelle de la ville.'),
                        SizedBox(height: 20),
                        _ValueLine(icon: Icons.volunteer_activism_outlined, title: 'Bénévole ou rémunéré', detail: 'Une distinction claire pour chaque annonce.'),
                        SizedBox(height: 20),
                        _ValueLine(icon: Icons.shield_outlined, title: 'Contact maîtrisé', detail: 'Vos coordonnées restent protégées.'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(bool compact) {
    final communes = ref.watch(communesProvider);
    final categories = ref.watch(categoriesProvider);

    final communeNames = communes.when(
      data: (items) => [for (final item in items) item.name],
      loading: () => const <String>[],
      error: (error, stack) => const <String>[],
    );
    final communeValues = <String>['', ...communeNames];
    final communeLabels = <String, String>{
      '': communes.hasError ? 'Communes indisponibles' : 'Toutes les communes',
    };

    final categoryItems = categories.when(
      data: (items) => items,
      loading: () => const <ReferenceItem>[],
      error: (error, stack) => const <ReferenceItem>[],
    );
    final categoryValues = <String>[
      '',
      ...categoryItems.map((item) => item.id.toString()),
    ];
    final categoryLabels = <String, String>{
      '': categories.hasError ? 'Catégories indisponibles' : 'Toutes les catégories',
      for (final item in categoryItems) item.id.toString(): item.name,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 24, compact ? 16 : 40, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qu’est-ce qu’il vous faut ?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: compact ? double.infinity : 360,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _refresh(),
                      decoration: const InputDecoration(
                        hintText: 'Ex. réparation, cours, déménagement',
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Mot-clé',
                      ),
                    ),
                  ),
                  _FilterDropdown(
                    label: 'Commune',
                    value: _commune,
                    values: communeValues,
                    labels: communeLabels,
                    onChanged: (value) => setState(() => _commune = value),
                  ),
                  _FilterDropdown(
                    label: 'Catégorie',
                    value: _categoryId,
                    values: categoryValues,
                    labels: categoryLabels,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  _FilterDropdown(
                    label: 'Type',
                    value: _type,
                    values: const ['', 'DEMANDE', 'OFFRE'],
                    labels: const {'': 'Tous les types', 'DEMANDE': 'Demande', 'OFFRE': 'Offre'},
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  _FilterDropdown(
                    label: 'Nature',
                    value: _nature,
                    values: const ['', 'BENEVOLE', 'REMUNEREE'],
                    labels: const {'': 'Toutes les natures', 'BENEVOLE': 'Bénévole', 'REMUNEREE': 'Rémunérée'},
                    onChanged: (value) => setState(() => _nature = value),
                  ),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.tune),
                    label: const Text('Rechercher'),
                    style: FilledButton.styleFrom(minimumSize: const Size(44, 52)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in ['Réparation', 'Cours', 'Aide à domicile', 'Déménagement'])
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () {
                        _searchController.text = suggestion;
                        _refresh();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActions(bool compact) {
    final announcement = _MainActionButton(
      title: 'Annonce',
      subtitle: 'Demander un service ou exprimer un besoin',
      icon: Icons.campaign_outlined,
      color: SoutraliColors.orange,
      foreground: SoutraliColors.ink,
      onPressed: () => _showPublicationChoices(isRequest: true),
    );
    final service = _MainActionButton(
      title: 'Prestation de service',
      subtitle: 'Proposer mes services à la communauté',
      icon: Icons.handyman_outlined,
      color: SoutraliColors.green,
      foreground: Colors.white,
      onPressed: () => _showPublicationChoices(isRequest: false),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 20, compact ? 16 : 40, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: compact
              ? Column(
                  children: [
                    announcement,
                    const SizedBox(height: 12),
                    service,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: announcement),
                    const SizedBox(width: 16),
                    Expanded(child: service),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeading() {
    final compact = MediaQuery.sizeOf(context).width < 500;

    return Padding(
      key: _resultsHeadingKey,
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 24, compact ? 16 : 40, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Annonces près de vous',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: compact ? 21 : 26),
                ),
              ),
              if (!compact) ...[
                const Icon(Icons.location_on_outlined, color: SoutraliColors.green, size: 18),
                const SizedBox(width: 4),
                const Text('Abidjan', style: TextStyle(color: SoutraliColors.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final networkError = error is DioException;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 38, color: SoutraliColors.muted),
              const SizedBox(height: 12),
              Text(
                networkError ? 'Le service est momentanément indisponible.' : 'Impossible de lire les annonces.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vérifiez que l’API locale est démarrée, puis réessayez.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(listingsProvider(_filters)),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 38, color: SoutraliColors.green),
            const SizedBox(height: 12),
            Text('Aucune annonce pour le moment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Essayez d’autres critères ou revenez un peu plus tard.'),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool compact) {
    return Container(
      decoration: const BoxDecoration(
        color: SoutraliColors.deepGreen,
        border: Border(top: BorderSide(color: SoutraliColors.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 40, vertical: 24),
      child: const Center(
        child: Text(
          'Soutrali · L’entraide à porter de main · Abidjan',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labels = const {},
  });

  final String label;
  final String value;
  final List<String> values;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    labels[item] ?? (item.isEmpty ? 'Toutes' : item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(growable: false),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isRequest = listing.type == 'DEMANDE';
    final isVolunteer = listing.nature == 'BENEVOLE';
    final date = listing.createdAt == null ? '' : DateFormat('d MMM', 'fr').format(listing.createdAt!);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _Tag(label: isRequest ? 'Demande' : 'Offre', color: isRequest ? SoutraliColors.paleOrange : SoutraliColors.paleGreen),
              _Tag(label: isVolunteer ? 'Bénévole' : 'Rémunérée', color: Colors.white, border: SoutraliColors.border),
            ],
          ),
          const SizedBox(height: 14),
          Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 7),
          Expanded(
            child: Text(listing.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: SoutraliColors.green),
              const SizedBox(width: 4),
              Expanded(child: Text(listing.commune, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)),
              Text(date, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          if (listing.category.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(listing.category, style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ],
        ),
      ),
      ),
    );
  }
}

class _PublicationChoice {
  const _PublicationChoice({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String kind;
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.color,
    required this.onTap,
  });

  final _PublicationChoice choice;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: SoutraliColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(choice.icon, color: color, size: 25),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(choice.title, style: const TextStyle(color: SoutraliColors.ink, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(choice.subtitle, style: const TextStyle(color: SoutraliColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SoutraliColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainActionButton extends StatelessWidget {
  const _MainActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          minimumSize: const Size(44, 82),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 27),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, maxLines: 2, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 2, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 19),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.border});

  final String label;
  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(label, style: const TextStyle(color: SoutraliColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(color: SoutraliColors.deepGreen, fontSize: 12, fontWeight: FontWeight.w700),
      );
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: SoutraliColors.green, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: SoutraliColors.ink, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: SoutraliColors.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      );
}