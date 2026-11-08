import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/motifs.dart';
import '../../theme/soutrali_theme.dart';
import '../account/account_repository.dart';
import '../account/contact_channels_section.dart';
import '../account/profile_safety_section.dart';
import '../auth/auth_repository.dart';
import '../errors/app_error.dart';
import '../errors/error_page.dart';
import '../location/geolocation.dart';
import '../location/location_prompt.dart';
import '../location/location_repository.dart';
import '../messaging/messaging_repository.dart';
import 'category_icons.dart';
import 'listing.dart';
import 'listing_skeleton.dart';
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

  ListingFilters get _filters {
    final location = ref.read(locationChoiceProvider);

    return ListingFilters(
      query: _searchController.text,
      commune: _commune,
      type: _type,
      nature: _nature,
      category: int.tryParse(_categoryId),
      // Position confirmée seulement : les annonces sont alors classées de
      // la plus proche à la plus lointaine.
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  @override
  void initState() {
    super.initState();
    // La proposition de localisation arrive après le premier rendu : la page
    // s’affiche immédiatement, la popup ne retarde jamais le contenu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForLocation());
  }

  /// Demande la position au navigateur, la fait reconnaître par l’API, puis
  /// propose une confirmation. Un refus, une position indisponible ou une
  /// panne de l’API laissent la page fonctionner normalement.
  Future<void> _askForLocation({bool force = false}) async {
    if (!force && ref.read(locationChoiceProvider).decision != LocationDecision.pending) {
      return;
    }

    final service = ref.read(geolocationServiceProvider);
    if (!service.isSupported) {
      return;
    }

    final position = await service.current();
    if (position == null || !mounted) {
      return;
    }

    final LocatedPlace place;
    try {
      place = await ref.read(locationRepositoryProvider).resolve(position);
    } catch (_) {
      return; // La localisation est un confort : jamais un écran d’erreur.
    }

    if (!mounted || !place.inServiceArea) {
      return;
    }

    final decision = await LocationPromptSheet.show(context, place);
    if (!mounted) {
      return;
    }

    if (decision == LocationDecision.confirmed) {
      ref.read(locationChoiceProvider.notifier).confirm(place);
    } else {
      ref.read(locationChoiceProvider.notifier).refuse();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// Retire d’un geste le mot-clé et tous les filtres actifs.
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _commune = '';
      _type = '';
      _nature = '';
      _categoryId = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final columns = width >= 1180 ? 3 : width >= 760 ? 2 : 1;
    final results = ref.watch(listingsProvider(_filters));
    final location = ref.watch(locationChoiceProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(compact)),
            SliverToBoxAdapter(child: _buildIntro(compact)),
            SliverToBoxAdapter(child: _buildMainActions(compact)),
            SliverToBoxAdapter(child: _buildSearch(compact)),
            SliverToBoxAdapter(child: _buildServices(compact)),
            SliverToBoxAdapter(
              child: _buildSectionHeading(location, resultCount: results.value?.length),
            ),
            results.when(
              // Squelettes animés : l’écran montre la forme des annonces qui
              // arrivent au lieu d’un rond de chargement sur fond vide.
              loading: () => ListingSkeletonGrid(
                columns: columns,
                cardCount: columns * 2,
                padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 8, compact ? 16 : 40, 48),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: ErrorPage(
                    compact: true,
                    error: AppError.fromException(error),
                    onRetry: () => ref.invalidate(listingsProvider(_filters)),
                  ),
                ),
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
                          mainAxisExtent: 272,
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
    final location = ref.watch(locationChoiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SoutraliColors.border.withValues(alpha: 0.9))),
        boxShadow: SoutraliShadows.soft(alpha: 0.04, blur: 18, y: 6),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 40, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              Image.asset(
                'assets/brand/soutrali-logo.png',
                width: compact ? 118 : 146,
                height: 46,
                fit: BoxFit.contain,
              ),
              if (!compact) ...[
                const SizedBox(width: 22),
                _LocationPill(
                  label: 'Abidjan · Côte d’Ivoire',
                  confirmed: location.isConfirmed,
                  onTap: () => _askForLocation(force: true),
                ),
              ],
              const Spacer(),
              if (!compact) ...[
                TextButton.icon(
                  onPressed: () => _showPublicationChoices(isRequest: false),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Publier'),
                  style: TextButton.styleFrom(foregroundColor: SoutraliColors.deepGreen),
                ),
                const SizedBox(width: 4),
              ],
              _buildAccountActions(context, compact: compact),
            ],
          ),
        ),
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
          case 'espace-admin':
            _openAdminPanel();
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
        if (canAccessAdminPanel(user))
          const PopupMenuItem(
            value: 'espace-admin',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 20),
                SizedBox(width: 10),
                Text('Espace admin'),
              ],
            ),
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

  /// Ouvre la console d’administration du back-office (`/admin`) sur
  /// l’hôte de l’API, dans un nouvel onglet du navigateur.
  Future<void> _openAdminPanel() async {
    final uri = Uri.parse('$apiBaseUrl/admin');
    var opened = false;

    try {
      opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir l’espace admin : vérifiez l’URL de l’API.'),
        ),
      );
    }
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
          ] else ...[
            if (canAccessAdminPanel(user))
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SoutraliColors.green),
                onPressed: _openAdminPanel,
                child: const Text('Espace admin'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _signOut();
              },
              child: const Text('Se déconnecter'),
            ),
          ],
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
                          DropdownMenuItem(
                            value: item.id.toString(),
                            child: Row(
                              children: [
                                Icon(categoryIcon(item.icon), size: 18, color: SoutraliColors.green),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
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
    // Les cartes d’exemple ont besoin de place : en dessous de 1 020 px, le
    // hero reste au texte et aux chiffres, sans collage à l’étroit.
    final wide = MediaQuery.sizeOf(context).width >= 1020;
    final categories = ref.watch(categoriesProvider).value ?? const <ReferenceItem>[];
    final communes = ref.watch(communesProvider).value ?? const <ReferenceItem>[];
    final listingsCount = categories.fold<int>(0, (total, item) => total + (item.listingsCount ?? 0));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: SoutraliGradients.hero),
        // Fond réactif : la grille de points s’éclaire sous le pointeur.
        child: InteractiveMotif(
          style: MotifStyle.brand,
          density: 44,
          opacity: 0.95,
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -70,
                child: _Halo(color: SoutraliColors.sun, size: 330, opacity: 0.26),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 40,
                  compact ? 26 : 36,
                  compact ? 20 : 40,
                  compact ? 22 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Reveal(
                                delay: 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _HeroEyebrow(),
                                    const SizedBox(height: 14),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(text: 'Un coup de main\n'),
                                          TextSpan(
                                            text: 'près de chez vous.',
                                            style: const TextStyle(color: SoutraliColors.sun),
                                          ),
                                        ],
                                      ),
                                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                            color: Colors.white,
                                            fontSize: compact ? 32 : 44,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 520),
                                      child: Text(
                                        'Trouvez une aide, proposez vos compétences et faites vivre l’entraide dans votre commune.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.84),
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    // Mobile : deux actions pleine largeur, bien
                                    // alignées ; desktop : côte à côte.
                                    if (compact)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _GradientButton(
                                            label: 'Explorer les annonces',
                                            icon: Icons.search_rounded,
                                            gradient: SoutraliGradients.warm,
                                            foreground: SoutraliColors.ink,
                                            height: 48,
                                            onPressed: _searchFocusNode.requestFocus,
                                          ),
                                          const SizedBox(height: 10),
                                          _GhostButton(
                                            label: 'Proposer un service',
                                            icon: Icons.handyman_outlined,
                                            onPressed: () => _showPublicationChoices(isRequest: false),
                                          ),
                                        ],
                                      )
                                    else
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _GradientButton(
                                            label: 'Explorer les annonces',
                                            icon: Icons.search_rounded,
                                            gradient: SoutraliGradients.warm,
                                            foreground: SoutraliColors.ink,
                                            height: 50,
                                            onPressed: _searchFocusNode.requestFocus,
                                          ),
                                          _GhostButton(
                                            label: 'Proposer un service',
                                            icon: Icons.handyman_outlined,
                                            onPressed: () => _showPublicationChoices(isRequest: false),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (wide) ...[
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: Reveal(delay: 180, child: _heroShowcase()),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _heroStats(
                          services: categories.length,
                          listings: listingsCount,
                          communes: communes.length,
                          compact: compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bandeau de chiffres : ils montent depuis zéro à l’arrivée sur la page.
  Widget _heroStats({
    required int services,
    required int listings,
    required int communes,
    required bool compact,
  }) {
    Widget stat(int value, String label) => Expanded(
          child: Column(
            key: ValueKey('hero-stat-$label'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountUp(
                value: value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12.5, height: 1.25),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.16))),
      ),
      child: Row(
        children: [
          stat(services, 'services couverts'),
          _HeroDivider(),
          stat(listings, 'annonces en ligne'),
          _HeroDivider(),
          stat(communes, 'communes d’Abidjan'),
        ],
      ),
    );
  }

  /// Deux cartes d’exemple inclinées : elles se redressent sous le pointeur.
  Widget _heroShowcase() {
    return SizedBox(
      height: 228,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 6,
            child: StraightenOnHover(
              turns: -0.028,
              child: const _HeroPreviewCard(
                icon: Icons.handyman_outlined,
                title: 'Réparation de ventilateurs',
                commune: 'Yopougon',
                distance: 'à 2,4 km',
                tag: 'Offre',
                gradient: SoutraliGradients.warm,
                foreground: SoutraliColors.ink,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: StraightenOnHover(
              turns: 0.024,
              child: const _HeroPreviewCard(
                icon: Icons.school,
                title: 'Cours de maths à domicile',
                commune: 'Cocody',
                distance: 'à 800 m',
                tag: 'Demande',
                gradient: SoutraliGradients.warm,
                foreground: SoutraliColors.ink,
                accent: SoutraliColors.green,
              ),
            ),
          ),
        ],
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

    final hasActiveFilter = _searchController.text.trim().isNotEmpty ||
        _commune.isNotEmpty ||
        _type.isNotEmpty ||
        _nature.isNotEmpty ||
        _categoryId.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 12, compact ? 16 : 40, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          // Le panneau se pose en fondu-glissé : entrée finie, pas de boucle.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 440),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 18 : 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: SoutraliColors.border),
                boxShadow: SoutraliShadows.soft(alpha: 0.09, blur: 38, y: 18),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveMotif(
                style: MotifStyle.light,
                density: 44,
                opacity: 0.8,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: SoutraliGradients.warm,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: SoutraliShadows.brand(SoutraliColors.orange),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 19, color: SoutraliColors.ink),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qu’est-ce qu’il vous faut ?',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: compact ? 21 : 25),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Décrivez votre besoin, choisissez votre commune : le reste se joue d’un geste.',
                              style: TextStyle(color: SoutraliColors.muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final field = TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _refresh(),
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Ex. réparation, cours, déménagement',
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Mot-clé',
                          filled: true,
                          fillColor: SoutraliColors.ivory,
                        ),
                      );
                      final button = _GradientButton(
                        label: 'Rechercher',
                        icon: Icons.search_rounded,
                        gradient: SoutraliGradients.forest,
                        foreground: Colors.white,
                        height: 56,
                        minWidth: 138,
                        onPressed: _refresh,
                      );

                      // Barre de recherche d’un seul tenant dès que la place
                      // le permet : le bouton reste au-dessus de la ligne de
                      // flottaison sur un écran de 1000 px de haut.
                      if (constraints.maxWidth < 560) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [field, const SizedBox(height: 10), button],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: field),
                          const SizedBox(width: 10),
                          button,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
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
                        icons: {
                          for (final item in categoryItems)
                            item.id.toString(): categoryIcon(item.icon),
                        },
                        onChanged: (value) => setState(() => _categoryId = value),
                      ),
                      _SegmentedFilter(
                        label: 'Type',
                        value: _type,
                        options: const {'': 'Tous', 'DEMANDE': 'Demande', 'OFFRE': 'Offre'},
                        accents: const {
                          '': SoutraliColors.deepGreen,
                          'DEMANDE': SoutraliColors.orange,
                          'OFFRE': SoutraliColors.green,
                        },
                        onChanged: (value) => setState(() => _type = value),
                      ),
                      _SegmentedFilter(
                        label: 'Nature',
                        value: _nature,
                        options: const {'': 'Toutes', 'BENEVOLE': 'Bénévole', 'REMUNEREE': 'Rémunérée'},
                        accents: const {
                          '': SoutraliColors.deepGreen,
                          'BENEVOLE': SoutraliColors.green,
                          'REMUNEREE': SoutraliColors.orange,
                        },
                        onChanged: (value) => setState(() => _nature = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, width: double.infinity, color: SoutraliColors.border),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final suggestion in const ['Réparation', 'Cours', 'Aide à domicile', 'Déménagement'])
                        _FilterPill(
                          label: suggestion,
                          selected: false,
                          dense: true,
                          onTap: () {
                            _searchController.text = suggestion;
                            _refresh();
                          },
                        ),
                      if (hasActiveFilter)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.close, size: 17),
                          label: const Text('Réinitialiser'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tous les services du référentiel, en visu interactive : chaque
  /// pastille filtre les annonces affichées juste en dessous (26 oct. 2026).
  Widget _buildServices(bool compact) {
    final categories = ref.watch(categoriesProvider);
    final items = categories.when(
      data: (rows) => rows,
      loading: () => const <ReferenceItem>[],
      error: (error, stack) => const <ReferenceItem>[],
    );

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final available = items.fold<int>(0, (total, item) => total + (item.listingsCount ?? 0));

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 14, compact ? 16 : 40, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 18 : 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: SoutraliColors.border),
              boxShadow: SoutraliShadows.soft(alpha: 0.05, blur: 26, y: 12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveMotif(
              style: MotifStyle.light,
              density: 56,
              opacity: 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tous les services',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: compact ? 18 : 21),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Choisissez un service : seules ses annonces s’affichent en dessous.',
                              style: TextStyle(color: SoutraliColors.muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: SoutraliColors.paleGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${items.length} services · $available annonces',
                            style: const TextStyle(
                              color: SoutraliColors.deepGreen,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Grille régulière : toutes les tuiles ont la même
                  // largeur et la même hauteur, quel que soit le nom du
                  // service (8 nov. 2026). Avant, des pastilles de largeur
                  // libre laissaient des trous et des lignes irrégulières.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 8.0;
                      final columns = constraints.maxWidth >= 880
                          ? 4
                          : constraints.maxWidth >= 600
                              ? 3
                              : 2;
                      final tileWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final item in items)
                            SizedBox(
                              width: tileWidth,
                              height: 72,
                              child: _ServiceTile(
                                key: ValueKey('service-${item.id}'),
                                icon: categoryIcon(item.icon),
                                label: item.name,
                                count: item.listingsCount,
                                selected: _categoryId == item.id.toString(),
                                onTap: () {
                                  setState(() {
                                    _categoryId = _categoryId == item.id.toString()
                                        ? ''
                                        : item.id.toString();
                                  });
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActions(bool compact) {
    final announcement = Reveal(
      delay: 60,
      child: HoverLift(
        rise: 5,
        child: _MainActionButton(
          title: 'Annonce',
          subtitle: 'Demander un service ou exprimer un besoin',
          icon: Icons.campaign_outlined,
          color: SoutraliColors.orange,
          foreground: SoutraliColors.ink,
          onPressed: () => _showPublicationChoices(isRequest: true),
        ),
      ),
    );
    final service = Reveal(
      delay: 140,
      child: HoverLift(
        rise: 5,
        child: _MainActionButton(
          title: 'Prestation de service',
          subtitle: 'Proposer mes services à la communauté',
          icon: Icons.handyman_outlined,
          color: SoutraliColors.green,
          foreground: Colors.white,
          onPressed: () => _showPublicationChoices(isRequest: false),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 16, compact ? 16 : 40, 4),
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

  Widget _buildSectionHeading(LocationChoice location, {int? resultCount}) {
    final compact = MediaQuery.sizeOf(context).width < 500;

    return Padding(
      key: _resultsHeadingKey,
      padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 26, compact ? 16 : 40, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Annonces près de vous',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: compact ? 21 : 28),
                        ),
                        if (resultCount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: SoutraliColors.ivoryDeep,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: SoutraliColors.peach),
                            ),
                            child: Text(
                              // L’API pagine : on annonce ce qui est affiché,
                              // sans laisser croire que la page est complète.
                              resultCount == 0
                                  ? 'aucun résultat'
                                  : '$resultCount résultat${resultCount > 1 ? 's' : ''}',
                              key: const ValueKey('results-count'),
                              style: const TextStyle(
                                color: SoutraliColors.orangeText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AnimatedAccent(),
                  ],
                ),
              ),
              if (!compact)
                _LocationPill(
                  label: location.isConfirmed ? location.place!.shortLabel : 'Abidjan',
                  confirmed: location.isConfirmed,
                  onTap: () => _askForLocation(force: true),
                  trailing: location.isConfirmed ? Icons.edit_location_alt_outlined : Icons.my_location,
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
      width: double.infinity,
      decoration: const BoxDecoration(gradient: SoutraliGradients.hero),
      padding: EdgeInsets.fromLTRB(compact ? 18 : 40, 30, compact ? 18 : 40, 26),
      child: InteractiveMotif(
        style: MotifStyle.dark,
        density: 28,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: SoutraliGradients.warm,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.handshake_outlined, size: 18, color: SoutraliColors.ink),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Soutrali',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'L’entraide à portée de main',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Abidjan · Côte d’Ivoire',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13),
                    ),
                    Text(
                      'Contact maîtrisé · annonces vérifiées',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13),
                    ),
                    Text(
                      '© 2026 Soutrali',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pilule de filtre animée : sélection colorée, survol relevé, appui
/// immédiat. Sert aux filtres gestuels (type, nature) et aux suggestions.
class _FilterPill extends StatefulWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = SoutraliColors.deepGreen,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final bool dense;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final accent = widget.accent;
    // L’orange de marque se lit mieux en encre sombre qu’en blanc.
    final foreground = selected
        ? (accent == SoutraliColors.orange ? SoutraliColors.ink : Colors.white)
        : SoutraliColors.ink;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.dense ? 13 : 15,
              vertical: widget.dense ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? accent
                  : (_hovered ? SoutraliColors.paleGreen : Colors.white),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? accent
                    : _hovered
                        ? SoutraliColors.green.withValues(alpha: 0.55)
                        : SoutraliColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: widget.dense ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Groupe de pilules segmentées (Type, Nature) : libellé au-dessus,
/// sélection immédiate sans menu déroulant.
class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.accents,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final Map<String, Color> accents;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: SoutraliColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in options.entries)
              _FilterPill(
                label: entry.value,
                selected: value == entry.key,
                accent: accents[entry.key] ?? SoutraliColors.deepGreen,
                onTap: () => onChanged(entry.key),
              ),
          ],
        ),
      ],
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
    this.icons = const {},
  });

  final String label;
  final String value;
  final List<String> values;
  final Map<String, String> labels;

  /// Icônes éventuelles de chaque entrée (services : icône de charte).
  final Map<String, IconData> icons;
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
            .map((item) {
              final icon = icons[item];
              final text = Text(
                labels[item] ?? (item.isEmpty ? 'Toutes' : item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

              return DropdownMenuItem(
                value: item,
                child: icon == null
                    ? text
                    : Row(
                        children: [
                          Icon(icon, size: 18, color: SoutraliColors.green),
                          const SizedBox(width: 8),
                          Flexible(child: text),
                        ],
                      ),
              );
            })
            .toList(growable: false),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

/// Tuile de service : icône de charte, nom sur deux lignes et nombre
/// d'annonces. Largeur et hauteur sont imposées par la grille appelante, pour
/// que tous les services s'alignent exactement les uns sous les autres.
class _ServiceTile extends StatefulWidget {
  const _ServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Nombre d'annonces disponibles pour ce service.
  final int? count;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final foreground = selected ? Colors.white : SoutraliColors.ink;
    final count = widget.count;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          gradient: selected ? SoutraliGradients.forest : null,
          color: selected ? null : (_hovered ? SoutraliColors.mint : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? SoutraliColors.green
                : _hovered
                    ? SoutraliColors.green.withValues(alpha: 0.55)
                    : SoutraliColors.border,
          ),
          boxShadow: selected
              ? SoutraliShadows.brand(SoutraliColors.green)
              : _hovered
                  ? SoutraliShadows.soft(alpha: 0.07, blur: 16, y: 8)
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: _hovered ? 1.06 : 1,
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.18)
                            : SoutraliColors.paleGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 17,
                        color: selected ? Colors.white : SoutraliColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          count == null
                              ? 'Aucune annonce'
                              : '$count annonce${count == 1 ? '' : 's'}',
                          key: ValueKey('service-count-${widget.label}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : SoutraliColors.muted,
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
      ),
    );
  }
}

class _ListingCard extends StatefulWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final isRequest = listing.type == 'DEMANDE';
    final isVolunteer = listing.nature == 'BENEVOLE';
    final date = listing.createdAt == null ? '' : DateFormat('d MMM', 'fr').format(listing.createdAt!);
    final gradient = isRequest ? SoutraliGradients.warm : SoutraliGradients.forest;
    final onGradient = isRequest ? SoutraliColors.ink : Colors.white;

    // Carte vivante : bandeau de service coloré, médaillon d’icône en filigrane,
    // puis le survol relève la carte et allume son liseré en 200 ms.
    return HoverLift(
      rise: 8,
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _hovered ? SoutraliColors.green : SoutraliColors.border,
                width: _hovered ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: _hovered
                  ? SoutraliShadows.brand(SoutraliColors.green)
                  : SoutraliShadows.soft(alpha: 0.05, blur: 18, y: 8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 82,
                  decoration: BoxDecoration(gradient: gradient),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -16,
                        bottom: -26,
                        child: Icon(
                          categoryIcon(listing.categoryIcon),
                          size: 116,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        top: 14,
                        child: Row(
                          children: [
                            _Tag(
                              label: isRequest ? 'Demande' : 'Offre',
                              color: Colors.white.withValues(alpha: 0.94),
                              foreground: SoutraliColors.ink,
                            ),
                            const SizedBox(width: 7),
                            _Tag(
                              label: isVolunteer ? 'Bénévole' : 'Rémunérée',
                              color: Colors.white.withValues(alpha: 0.16),
                              foreground: onGradient,
                              border: Colors.white.withValues(alpha: 0.34),
                            ),
                            const Spacer(),
                            if (listing.distanceKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.near_me_outlined, size: 12, color: SoutraliColors.orangeText),
                                    const SizedBox(width: 4),
                                    Text(
                                      listingDistanceLabel(listing.distanceKm!),
                                      key: const ValueKey('listing-distance'),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: SoutraliColors.orangeText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          listing.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        if (listing.category.isNotEmpty) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon(listing.categoryIcon), size: 15, color: SoutraliColors.orange),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  listing.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SoutraliColors.orangeText,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 15, color: SoutraliColors.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                listing.commune,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: SoutraliColors.muted, fontSize: 13),
                              ),
                            ),
                            Text(date, style: const TextStyle(color: SoutraliColors.muted, fontSize: 13)),
                            const SizedBox(width: 6),
                            AnimatedOpacity(
                              opacity: _hovered ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: SoutraliColors.paleGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: SoutraliColors.deepGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

class _MainActionButton extends StatefulWidget {
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
  State<_MainActionButton> createState() => _MainActionButtonState();
}

class _MainActionButtonState extends State<_MainActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.color == SoutraliColors.orange
        ? SoutraliGradients.warm
        : SoutraliGradients.forest;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _hovered
              ? SoutraliShadows.brand(widget.color)
              : SoutraliShadows.soft(alpha: 0.08, blur: 24, y: 12),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  top: -46,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                ),
                Positioned(
                  left: -26,
                  bottom: -64,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Icon(widget.icon, size: 25, color: widget.foreground),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: widget.foreground,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: widget.foreground.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSlide(
                        offset: _hovered ? const Offset(0.28, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_rounded, size: 17, color: widget.foreground),
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
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    this.border,
    this.foreground = SoutraliColors.ink,
  });

  final String label;
  final Color color;
  final Color? border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Bouton principal en dégradé : ombre de marque et léger grossissement au
/// survol, appui réel via `InkWell`.
class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.foreground,
    required this.onPressed,
    this.height = 46,
    this.minWidth = 0,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color foreground;
  final VoidCallback onPressed;
  final double height;
  final double minWidth;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: Container(
          height: widget.height,
          constraints: BoxConstraints(minWidth: widget.minWidth),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovered
                ? SoutraliShadows.brand(SoutraliColors.orange)
                : SoutraliShadows.soft(alpha: 0.10, blur: 18, y: 8),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 18, color: widget.foreground),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Action secondaire sur fond de marque : contour translucide, texte blanc.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

/// Pastille de lieu : le point vert indique une position confirmée.
class _LocationPill extends StatefulWidget {
  const _LocationPill({
    required this.label,
    required this.confirmed,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool confirmed;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  State<_LocationPill> createState() => _LocationPillState();
}

class _LocationPillState extends State<_LocationPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _hovered ? SoutraliColors.paleGreen : SoutraliColors.ivory,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _hovered
                    ? SoutraliColors.green.withValues(alpha: 0.45)
                    : SoutraliColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.confirmed ? SoutraliColors.green : SoutraliColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SoutraliColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  widget.trailing ?? Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: SoutraliColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Halo circulaire décoratif des fonds de marque.
class _Halo extends StatelessWidget {
  const _Halo({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

/// Étiquette du hero : petite pilule posée sur le dégradé vert.
class _HeroEyebrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: SoutraliColors.sun, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'ENTRAIDE DE PROXIMITÉ · ABIDJAN',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d’exemple du hero : illustration de ce qu’on trouve sur Soutrali.
class _HeroPreviewCard extends StatelessWidget {
  const _HeroPreviewCard({
    required this.icon,
    required this.title,
    required this.commune,
    required this.distance,
    required this.tag,
    required this.gradient,
    required this.foreground,
    this.accent = SoutraliColors.orange,
  });

  final IconData icon;
  final String title;
  final String commune;
  final String distance;
  final String tag;
  final LinearGradient gradient;
  final Color foreground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SoutraliColors.ink.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 22, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: SoutraliColors.ink,
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      commune,
                      style: const TextStyle(color: SoutraliColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.near_me_outlined, size: 12, color: SoutraliColors.orangeText),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  distance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SoutraliColors.orangeText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Exemple assumé : ces deux cartes illustrent la page, elles ne
              // prétendent pas être de vraies annonces vérifiées.
              Text(
                'Exemple',
                style: TextStyle(
                  color: SoutraliColors.muted.withValues(alpha: 0.8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}