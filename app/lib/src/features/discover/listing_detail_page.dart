import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/motifs.dart';
import '../../theme/soutrali_theme.dart';
import '../account/account_repository.dart';
import '../auth/auth_repository.dart';
import '../messaging/messaging_repository.dart';
import 'category_icons.dart';
import 'listing.dart';
import 'listings_repository.dart';

/// Détail d’une annonce : informations, contact de l’auteur et signalement.
class ListingDetailPage extends ConsumerWidget {
  const ListingDetailPage({super.key, required this.listingId});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingProvider(listingId));
    final auth = ref.watch(authProvider);
    final user = auth.value;

    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      appBar: AppBar(
        backgroundColor: SoutraliColors.deepGreen,
        foregroundColor: Colors.white,
        title: const Text('Annonce'),
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
        child: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 38, color: SoutraliColors.muted),
                const SizedBox(height: 12),
                const Text('Impossible de charger cette annonce.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(listingProvider(listingId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Cette annonce n’existe pas ou n’est plus disponible.'),
              ),
            );
          }

          final isMine = user != null && listing.authorId == user.id;
          final blockedIds = ref.watch(blockedUsersProvider).value ?? const <BlockedUser>[];
          final isBlocked = listing.authorId != null && blockedIds.any((account) => account.id == listing.authorId);
          final channels = ref.watch(listingChannelsProvider(listingId)).value ?? const <ContactChannel>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: listing.type == 'DEMANDE' ? 'Demande' : 'Offre',
                          color: listing.type == 'DEMANDE' ? SoutraliColors.paleOrange : SoutraliColors.paleGreen,
                        ),
                        _Chip(
                          label: listing.nature == 'BENEVOLE' ? 'Bénévole' : 'Rémunérée',
                          color: Colors.white,
                        ),
                        if (listing.category.isNotEmpty)
                          _Chip(
                            label: listing.category,
                            color: Colors.white,
                            icon: categoryIcon(listing.categoryIcon),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(listing.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    const AnimatedAccent(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _Meta(icon: Icons.location_on_outlined, text: listing.commune),
                        if (listing.authorName != null)
                          _Meta(icon: Icons.person_outline, text: 'Publié par ${listing.authorName}'),
                        if (listing.createdAt != null)
                          _Meta(
                            icon: Icons.calendar_today_outlined,
                            text: DateFormat('d MMMM yyyy', 'fr').format(listing.createdAt!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: SoutraliColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listing.description, style: Theme.of(context).textTheme.bodyLarge),
                          if (listing.availability != null && listing.availability!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _DetailLine(label: 'Disponibilité', value: listing.availability!),
                          ],
                          if (listing.budget != null) ...[
                            const SizedBox(height: 10),
                            _DetailLine(
                              label: 'Budget indicatif',
                              value: '${listing.budget!.round()} F',
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isMine && !isBlocked && channels.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SoutraliColors.paleGreen,
                          border: Border.all(color: SoutraliColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Canaux de contact choisis par l’auteur',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            for (final channel in channels)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _DetailLine(label: channel.label, value: channel.value),
                              ),
                            const SizedBox(height: 4),
                            const Text(
                              'Visibles uniquement parce que vous êtes connecté ; la messagerie interne reste recommandée.',
                              style: TextStyle(color: SoutraliColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (isMine) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SoutraliColors.paleGreen,
                          border: Border.all(color: SoutraliColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'C’est votre annonce : elle n’est pas contactable par votre propre compte.',
                              style: TextStyle(color: SoutraliColors.ink),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => context.go('/mes-annonces'),
                              icon: const Icon(Icons.manage_accounts_outlined),
                              label: const Text('Gérer mes annonces'),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isBlocked) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SoutraliColors.paleOrange,
                          border: Border.all(color: SoutraliColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vous avez bloqué ce compte : la messagerie est désactivée dans les deux sens.',
                              style: TextStyle(color: SoutraliColors.ink),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _unblock(context, ref, listing),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Débloquer'),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.flag_outlined),
                                  label: const Text('Signaler'),
                                  onPressed: () => _report(context, ref, listing, user),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: SoutraliColors.green,
                                minimumSize: const Size(44, 48),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Contacter l’auteur'),
                              onPressed: () => _contact(context, ref, listing, user),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Signaler'),
                            onPressed: () => _report(context, ref, listing, user),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Le contact se fait par la messagerie interne du site, réservée aux comptes connectés.',
                        style: TextStyle(color: SoutraliColors.muted, fontSize: 13),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _block(context, ref, listing),
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text('Bloquer ce compte'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;

  /// Icône de charte du service (facultative).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: SoutraliColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: SoutraliColors.green),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(color: SoutraliColors.ink, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: SoutraliColors.green),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: SoutraliColors.muted)),
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
