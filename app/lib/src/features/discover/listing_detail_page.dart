import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../format/date.dart';
import '../../format/money.dart';
import '../../theme/motifs.dart';
import '../../theme/soutrali_theme.dart';
import '../account/account_repository.dart';
import '../auth/auth_repository.dart';
import '../errors/app_error.dart';
import '../errors/error_page.dart';
import '../messaging/messaging_repository.dart';
import 'category_icons.dart';
import 'listing.dart';
import 'listings_repository.dart';

// Le titre des barres de cette page : le thème les destine au vert profond.
const _barTitle = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: SoutraliColors.ink,
);

/// Détail d’une annonce : le prix, le lieu, la disponibilité, l’auteur, les
/// conseils de sécurité, les annonces voisines et le contact.
///
/// La page se lit de haut en bas comme une fiche de service : un bandeau de
/// marque, le montant annoncé mis en avant, les repères en tuiles, le texte de
/// l’annonce, puis la confiance (auteur, conseils) avant les actions.
class ListingDetailPage extends ConsumerWidget {
  const ListingDetailPage({super.key, required this.listingId});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingProvider(listingId));
    final user = ref.watch(authProvider).value;

    return listingAsync.when(
      loading: () => _scaffold(
        context,
        body: const Center(child: CircularProgressIndicator()),
      ),
      // Panne, coupure réseau ou erreur serveur : chaque cas a son écran.
      error: (error, stack) => _scaffold(
        context,
        body: ErrorPage(
          error: AppError.fromException(error),
          onRetry: () => ref.invalidate(listingProvider(listingId)),
        ),
      ),
      data: (listing) {
        // L’API renvoie 404 pour une annonce retirée : page dédiée.
        if (listing == null) {
          return _scaffold(
            context,
            body: ErrorPage(
              error: AppError.fromStatus(404)!,
              titleOverride: 'Annonce introuvable',
              location: '/listing/$listingId',
            ),
          );
        }

        final isMine = user != null && listing.authorId == user.id;
        final blockedIds = ref.watch(blockedUsersProvider).value ?? const <BlockedUser>[];
        final isBlocked =
            listing.authorId != null && blockedIds.any((account) => account.id == listing.authorId);
        final channels = ref.watch(listingChannelsProvider(listingId)).value ?? const <ContactChannel>[];

        return Scaffold(
          backgroundColor: SoutraliColors.ivory,
          appBar: _buildBar(context, ref, listing, user, isMine: isMine, isBlocked: isBlocked),
          bottomNavigationBar: _BottomBar(
            listing: listing,
            isMine: isMine,
            isBlocked: isBlocked,
            onManage: () => context.go('/mes-annonces'),
            onContact: () => _contact(context, ref, listing, user),
          ),
          body: InteractiveMotif(
            style: MotifStyle.light,
            density: 44,
            opacity: 0.6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Hero(listing: listing),
                      const SizedBox(height: 16),
                      _PriceBanner(listing: listing),
                      const SizedBox(height: 16),
                      _FactsGrid(listing: listing),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'À propos de cette annonce',
                        icon: Icons.notes_rounded,
                        child: Text(
                          listing.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                        ),
                      ),
                      if (!isMine && !isBlocked && channels.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Canaux de contact de l’auteur',
                          icon: Icons.alternate_email_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final channel in channels)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _DetailLine(label: channel.label, value: channel.value),
                                ),
                              const SizedBox(height: 2),
                              const Text(
                                'Visibles uniquement parce que vous êtes connecté ; la messagerie interne reste recommandée.',
                                style: TextStyle(color: SoutraliColors.muted, fontSize: 12.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _AuthorCard(listing: listing),
                      const SizedBox(height: 16),
                      const _SafetyCard(),
                      if (!isMine) ...[
                        const SizedBox(height: 16),
                        _SimilarListings(listing: listing),
                      ],
                      if (isMine) ...[
                        const SizedBox(height: 16),
                        _NoticeCard(
                          color: SoutraliColors.paleGreen,
                          icon: Icons.person_outline_rounded,
                          text: 'C’est votre annonce : elle n’est pas contactable par votre propre compte.',
                          action: TextButton.icon(
                            onPressed: () => context.go('/mes-annonces'),
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Gérer mes annonces'),
                          ),
                        ),
                      ] else if (isBlocked) ...[
                        const SizedBox(height: 16),
                        _NoticeCard(
                          color: SoutraliColors.paleOrange,
                          icon: Icons.block,
                          text: 'Vous avez bloqué ce compte : la messagerie est désactivée dans les deux sens.',
                          action: TextButton.icon(
                            onPressed: () => _unblock(context, ref, listing),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Débloquer'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _block(context, ref, listing),
                            icon: const Icon(Icons.block, size: 18),
                            label: const Text('Bloquer ce compte'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scaffold(BuildContext context, {required Widget body}) {
    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      appBar: AppBar(
        backgroundColor: SoutraliColors.ivory,
        foregroundColor: SoutraliColors.ink,
        title: const Text('Annonce', style: _barTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SoutraliColors.deepGreen),
          tooltip: 'Retour',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: body,
    );
  }

  /// Barre du haut : retour, copie du lien (utile pour partager par WhatsApp)
  /// et un menu qui ne montre que les actions possibles.
  AppBar _buildBar(
    BuildContext context,
    WidgetRef ref,
    Listing listing,
    AuthUser? user, {
    required bool isMine,
    required bool isBlocked,
  }) {
    return AppBar(
      backgroundColor: SoutraliColors.ivory,
      foregroundColor: SoutraliColors.ink,
      title: const Text('Annonce', style: _barTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SoutraliColors.deepGreen),
        tooltip: 'Retour',
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      actions: [
        IconButton(
          key: const ValueKey('listing-copy-link'),
          tooltip: 'Copier le lien',
          icon: const Icon(Icons.link_rounded, color: SoutraliColors.deepGreen),
          onPressed: () => _copyLink(context),
        ),
        if (!isMine)
          PopupMenuButton<String>(
            tooltip: 'Plus d’actions',
            icon: const Icon(Icons.more_vert, color: SoutraliColors.deepGreen),
            onSelected: (value) {
              switch (value) {
                case 'report':
                  _report(context, ref, listing, user);
                case 'block':
                  _block(context, ref, listing);
                case 'unblock':
                  _unblock(context, ref, listing);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Signaler l’annonce'),
                ),
              ),
              PopupMenuItem(
                value: isBlocked ? 'unblock' : 'block',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block),
                  title: Text(isBlocked ? 'Débloquer ce compte' : 'Bloquer ce compte'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final link = Uri.base.replace(fragment: '/listing/$listingId').toString();
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien de l’annonce copié.')),
    );
  }

  void _loginFirst(BuildContext context, String from) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connectez-vous pour continuer.')),
    );
    context.go('/login?from=${Uri.encodeComponent(from)}');
  }

  void _contact(BuildContext context, WidgetRef ref, Listing listing, AuthUser? user) {
    if (user == null) {
      _loginFirst(context, '/listing/$listingId');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ContactDialog(
        listing: listing,
        onSend: (message) async {
          final conversationId = await ref
              .read(messagingRepositoryProvider)
              .start(listingId: listing.id, message: message);

          ref.invalidate(conversationsProvider);

          if (!dialogContext.mounted) return;
          Navigator.pop(dialogContext);
          context.go('/messagerie/$conversationId');
        },
      ),
    );
  }

  void _report(BuildContext context, WidgetRef ref, Listing listing, AuthUser? user) {
    if (user == null) {
      _loginFirst(context, '/listing/$listingId');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ReportDialog(
        onSend: (reason, details) => ref.read(accountRepositoryProvider).report(
              listing.id,
              reason: reason,
              details: details,
            ),
      ),
    );
  }

  /// Bloquer l’auteur (T-14) : la messagerie est désactivée dans les deux sens.
  Future<void> _block(BuildContext context, WidgetRef ref, Listing listing) async {
    final authorId = listing.authorId;
    if (authorId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.block, color: SoutraliColors.danger),
        title: const Text('Bloquer ce compte ?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const Text(
            'Vous ne pourrez plus échanger par messagerie avec ce compte, '
            'ni lui, ni vous. Vous pourrez débloquer depuis votre profil. '
            'Aucune annonce n’est supprimée.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SoutraliColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(accountRepositoryProvider).block(authorId);
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(listingProvider(listingId));
      ref.invalidate(listingChannelsProvider(listingId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte bloqué : messagerie désactivée.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref, Listing listing) async {
    final authorId = listing.authorId;
    if (authorId == null) return;

    try {
      await ref.read(accountRepositoryProvider).unblock(authorId);
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(listingProvider(listingId));
      ref.invalidate(listingChannelsProvider(listingId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte débloqué : la messagerie est rétablie.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }
}

/// Bandeau de marque : service, type, nature, titre, repères de lieu et de date.
class _Hero extends StatelessWidget {
  const _Hero({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isRequest = listing.type == 'DEMANDE';
    final onHeader = isRequest ? SoutraliColors.ink : Colors.white;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isRequest ? SoutraliGradients.warm : SoutraliGradients.forest,
        borderRadius: BorderRadius.circular(26),
        boxShadow: SoutraliShadows.brand(
          isRequest ? SoutraliColors.orange : SoutraliColors.green,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -40,
            child: Icon(
              categoryIcon(listing.categoryIcon),
              size: 210,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(categoryIcon(listing.categoryIcon), size: 27, color: onHeader),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderTag(
                            label: isRequest ? 'Demande' : 'Offre',
                            foreground: onHeader,
                            strong: true,
                          ),
                          _HeaderTag(
                            label: listing.nature == 'BENEVOLE' ? 'Bénévole' : 'Rémunérée',
                            foreground: onHeader,
                          ),
                          if (listing.category.isNotEmpty)
                            _HeaderTag(
                              label: listing.category,
                              foreground: onHeader,
                              icon: categoryIcon(listing.categoryIcon),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  listing.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: onHeader, fontSize: 29, height: 1.16),
                ),
                const SizedBox(height: 10),
                AnimatedAccent(
                  color: isRequest ? SoutraliColors.ink : SoutraliColors.sun,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _Meta(icon: Icons.location_on_outlined, text: listing.commune, color: onHeader),
                    if (listing.distanceKm != null)
                      _Meta(
                        icon: Icons.near_me_outlined,
                        text: listingDistanceLabel(listing.distanceKm!),
                        color: onHeader,
                      ),
                    _Meta(
                      icon: Icons.schedule_rounded,
                      text: publishedAgo(listing.createdAt),
                      color: onHeader,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Montant annoncé, en grand : c’est l’information que l’on cherche d’abord.
class _PriceBanner extends StatelessWidget {
  const _PriceBanner({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isVolunteer = listing.nature == 'BENEVOLE';
    final amount = listing.budget;

    final (label, value, note) = switch ((isVolunteer, amount)) {
      (true, _) => (
          'Bénévolat',
          'Gratuit',
          'Service rendu sans contrepartie, par choix de l’auteur.',
        ),
      (false, final num budget) => (
          'Rémunération annoncée',
          fcfa(budget),
          'Montant indiqué par l’auteur — à confirmer lors de l’échange.',
        ),
      _ => (
          'Rémunération',
          'À convenir',
          'L’auteur n’a pas précisé de montant : demandez-lui avant de vous engager.',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoutraliShadows.soft(alpha: 0.05, blur: 20, y: 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isVolunteer ? SoutraliColors.paleOrange : SoutraliColors.paleGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isVolunteer ? Icons.volunteer_activism_rounded : Icons.payments_rounded,
              color: isVolunteer ? SoutraliColors.orangeText : SoutraliColors.deepGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: SoutraliColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  key: const ValueKey('listing-amount'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isVolunteer ? SoutraliColors.orangeText : SoutraliColors.ink,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(color: SoutraliColors.muted, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Repères pratiques : lieu, disponibilité, publication, référence.
class _FactsGrid extends StatelessWidget {
  const _FactsGrid({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final availability = listing.availability;
    final tiles = <Widget>[
      _InfoTile(
        icon: Icons.location_on_outlined,
        label: 'Lieu',
        value: listing.commune.isEmpty ? 'Abidjan' : listing.commune,
      ),
      _InfoTile(
        icon: Icons.event_available_outlined,
        label: 'Disponibilité',
        value: availability != null && availability.isNotEmpty ? availability : 'À convenir',
      ),
      _InfoTile(
        icon: Icons.schedule_rounded,
        label: 'Publication',
        value: publishedAgo(listing.createdAt),
      ),
      _InfoTile(
        icon: Icons.tag_rounded,
        label: 'Référence',
        value: 'N° ${listing.id}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Deux colonnes dès qu’un téléphone le permet : la fiche tient alors
        // en un écran et demi au lieu de trois.
        if (constraints.maxWidth < 320) {
          return Column(
            children: [
              for (final tile in tiles)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: tile),
            ],
          );
        }

        // Deux tuiles d’une même ligne prennent la même hauteur, sinon la
        // grille ressemble à un escalier quand la disponibilité est longue.
        return Column(
          children: [
            for (var row = 0; row < tiles.length; row += 2)
              Padding(
                padding: EdgeInsets.only(bottom: row + 2 < tiles.length ? 12 : 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tiles[row]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: row + 1 < tiles.length ? tiles[row + 1] : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SoutraliColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SoutraliColors.paleGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: SoutraliColors.deepGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: SoutraliColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SoutraliColors.ink,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de section homogène : titre, icône et contenu.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoutraliShadows.soft(alpha: 0.04, blur: 18, y: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: SoutraliColors.deepGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: SoutraliColors.ink,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Qui publie : l’auteur, son compte, et un rappel que la messagerie est le
/// canal normal.
class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.listing});

  final Listing listing;

  String get _initials {
    final name = listing.authorName?.trim() ?? '';
    if (name.isEmpty) return 'S';
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final letters = parts.take(2).map((part) => part.substring(0, 1)).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = listing.authorName ?? 'Auteur Soutrali';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: SoutraliGradients.forest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SoutraliColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Auteur de l’annonce · compte Soutrali',
                  style: TextStyle(fontSize: 12.5, color: SoutraliColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SoutraliColors.paleGreen,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_outlined, size: 13, color: SoutraliColors.deepGreen),
                SizedBox(width: 5),
                Text(
                  'Messagerie',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SoutraliColors.deepGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Conseils avant de s’engager : honnêtes, généraux, et utiles dans un
/// contexte ivoirien où les acomptes par Mobile Money sont courants.
class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  static const _rules = <String>[
    'Écrivez d’abord par la messagerie Soutrali : l’échange reste tracé.',
    'Ne versez aucun acompte avant d’avoir vu la prestation, le lieu ou la personne.',
    'Méfiez-vous des prix trop bas et des demandes de paiement hors plateforme.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: SoutraliColors.ivoryDeep,
        border: Border.all(color: SoutraliColors.peach),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 18, color: SoutraliColors.orangeText),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Avant de vous engager',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: SoutraliColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final rule in _rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 5, color: SoutraliColors.orangeText),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SoutraliColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Trois annonces de la même commune, pour ne pas s’arrêter à la première.
class _SimilarListings extends ConsumerWidget {
  const _SimilarListings({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listing.commune.isEmpty) return const SizedBox.shrink();

    final nearby = ref.watch(listingsProvider(ListingFilters(commune: listing.commune)));
    final others = (nearby.value ?? const <Listing>[])
        .where((other) => other.id != listing.id)
        .take(3)
        .toList(growable: false);

    if (others.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'À découvrir aussi à ${listing.commune}',
      icon: Icons.explore_outlined,
      child: Column(
        children: [
          for (final other in others)
            _MiniListing(
              listing: other,
              onTap: () => context.push('/listing/${other.id}'),
            ),
        ],
      ),
    );
  }
}

class _MiniListing extends StatelessWidget {
  const _MiniListing({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVolunteer = listing.nature == 'BENEVOLE';
    final price = isVolunteer
        ? 'Bénévole'
        : listing.budget == null
            ? 'À convenir'
            : fcfa(listing.budget);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SoutraliColors.paleGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon(listing.categoryIcon),
                  size: 19,
                  color: SoutraliColors.deepGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: SoutraliColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing.category} · ${publishedAgo(listing.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: SoutraliColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                price,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isVolunteer ? SoutraliColors.orangeText : SoutraliColors.deepGreen,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: SoutraliColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action principale toujours à portée de pouce : le montant et « Contacter ».
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.listing,
    required this.isMine,
    required this.isBlocked,
    required this.onManage,
    required this.onContact,
  });

  final Listing listing;
  final bool isMine;
  final bool isBlocked;
  final VoidCallback onManage;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final isVolunteer = listing.nature == 'BENEVOLE';
    final price = isVolunteer
        ? 'Bénévolat'
        : listing.budget == null
            ? 'Montant à convenir'
            : fcfa(listing.budget);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: SoutraliColors.border)),
        boxShadow: SoutraliShadows.soft(alpha: 0.07, blur: 22, y: -6),
      ),
      child: SafeArea(
        top: false,
        // `heightFactor: 1` : la barre prend la hauteur de son contenu.
        // Sans cela, `Center` s’étire sur toute la hauteur offerte par le
        // `Scaffold` et recouvre le corps de la page.
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVolunteer ? 'SERVICE BÉNÉVOLE' : 'RÉMUNÉRATION',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: SoutraliColors.muted,
                          ),
                        ),
                        Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: SoutraliColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isMine)
                    OutlinedButton.icon(
                      onPressed: onManage,
                      icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                      label: const Text('Gérer'),
                    )
                  else if (isBlocked)
                    const Text(
                      'Compte bloqué',
                      style: TextStyle(fontSize: 12.5, color: SoutraliColors.muted),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey('listing-contact'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SoutraliColors.green,
                        minimumSize: const Size(44, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Contacter'),
                      onPressed: onContact,
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

/// Encart d’information contextuel (annonce personnelle, compte bloqué).
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.color,
    required this.icon,
    required this.text,
    required this.action,
  });

  final Color color;
  final IconData icon;
  final String text;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: SoutraliColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: SoutraliColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
          action,
        ],
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.listing, required this.onSend});

  final Listing listing;
  final Future<void> Function(String message) onSend;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.length < 2) {
      setState(() => _error = 'Écrivez un court message (2 caractères minimum).');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.onSend(message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.chat_bubble_outline, color: SoutraliColors.green),
      title: const Text('Contacter l’auteur'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À propos de « ${widget.listing.title} »',
              style: const TextStyle(color: SoutraliColors.muted),
            ),
            if (widget.listing.budget != null || widget.listing.nature == 'BENEVOLE') ...[
              const SizedBox(height: 6),
              Text(
                widget.listing.nature == 'BENEVOLE'
                    ? 'Annonce bénévole.'
                    : 'Rémunération annoncée : ${fcfa(widget.listing.budget)}.',
                style: const TextStyle(
                  color: SoutraliColors.deepGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Votre message',
                hintText: 'Présentez votre demande en quelques mots…',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SoutraliColors.green,
            minimumSize: const Size(44, 44),
          ),
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.onSend});

  final Future<void> Function(String reason, String? details) onSend;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = [
    'Contenu inapproprié',
    'Fausse annonce ou arnaque',
    'Hors sujet',
    'Autre raison',
  ];

  String _reason = _reasons.first;
  final _detailsController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.onSend(_reason, _detailsController.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement enregistré. Suivez son état depuis votre profil.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.flag_outlined, color: SoutraliColors.orange),
      title: const Text('Signaler cette annonce'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Le signalement est transmis à la modération de la plateforme.'),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Motif'),
              items: [
                for (final reason in _reasons) DropdownMenuItem(value: reason, child: Text(reason)),
              ],
              onChanged: (value) => setState(() => _reason = value ?? _reasons.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detailsController,
              minLines: 2,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Détails (facultatif)',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SoutraliColors.orange,
            foregroundColor: SoutraliColors.ink,
            minimumSize: const Size(44, 44),
          ),
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Envoyer le signalement'),
        ),
      ],
    );
  }
}

/// Étiquette posée sur le bandeau de marque : contraste garanti par
/// `foreground`, jamais par une couleur fixe.
class _HeaderTag extends StatelessWidget {
  const _HeaderTag({
    required this.label,
    required this.foreground,
    this.icon,
    this.strong = false,
  });

  final String label;
  final Color foreground;
  final IconData? icon;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: strong ? 0.94 : 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: strong ? 0 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: strong ? SoutraliColors.ink : foreground,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color = SoutraliColors.muted});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 13.5)),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
