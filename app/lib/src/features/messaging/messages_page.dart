import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/motifs.dart';
import '../../theme/soutrali_theme.dart';
import '../auth/auth_repository.dart';
import 'messaging_repository.dart';

/// Messagerie interne (D-05) : liste des fils et lecture d’un fil.
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key, this.conversationId});

  final int? conversationId;

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _redirecting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _requireAuth(AuthUser? user) {
    if (user == null && !_redirecting) {
      _redirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login?from=${Uri.encodeComponent('/messagerie')}');
        }
      });
    }
  }

  Future<void> _send(int conversationId) async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await ref.read(messagingRepositoryProvider).send(conversationId: conversationId, body: body);
      _messageController.clear();
      ref.invalidate(threadProvider(conversationId));
      ref.invalidate(conversationsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.value;
    _requireAuth(user);

    final conversations = ref.watch(conversationsProvider);
    final selectedId = widget.conversationId;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    // Au premier affichage d’un fil, les messages reçus sont marqués lus :
    // on rafraîchit le compteur de non-lus de l’en-tête.
    if (selectedId != null) {
      ref.listen(threadProvider(selectedId), (previous, next) {
        if (next.hasValue && previous?.hasValue != true) {
          ref.invalidate(conversationsProvider);
        }
      });
    }

    final thread = selectedId == null ? null : ref.watch(threadProvider(selectedId));

    final listPanel = Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InteractiveMotif(
            style: MotifStyle.light,
            density: 30,
            opacity: 0.7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Messagerie',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Expanded(
            child: conversations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('Chargement impossible.')),
              data: (snapshot) => snapshot.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucune conversation pour le moment.\n\nOuvrez une annonce et contactez son auteur pour démarrer un échange.',
                        style: TextStyle(color: SoutraliColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: snapshot.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = snapshot.items[index];
                        final selected = item.id == selectedId;

                        return ListTile(
                          selected: selected,
                          selectedTileColor: SoutraliColors.paleGreen,
                          leading: CircleAvatar(
                            backgroundColor: SoutraliColors.paleGreen,
                            child: Text(
                              item.participantName.isEmpty
                                  ? '?'
                                  : item.participantName[0].toUpperCase(),
                              style: const TextStyle(color: SoutraliColors.deepGreen),
                            ),
                          ),
                          title: Text(
                            item.participantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${item.listingTitle}\n${item.lastMessage ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: item.unread > 0
                              ? CircleAvatar(
                                  radius: 12,
                                  backgroundColor: SoutraliColors.orange,
                                  child: Text(
                                    '${item.unread}',
                                    style: const TextStyle(fontSize: 12, color: SoutraliColors.ink),
                                  ),
                                )
                              : null,
                          onTap: () => context.go('/messagerie/${item.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );

    final threadPanel = selectedId == null
        ? InteractiveMotif(
            style: MotifStyle.light,
            density: 40,
            opacity: 0.7,
            child: const Center(
              child: Text('Choisissez une conversation pour lire les messages.',
                  style: TextStyle(color: SoutraliColors.muted)),
            ),
          )
        : thread == null
            ? const Center(child: CircularProgressIndicator())
            : thread.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Impossible de charger cette conversation.'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(threadProvider(selectedId)),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (conversation) => _ThreadView(
                  conversation: conversation,
                  controller: _messageController,
                  sending: _sending,
                  wide: wide,
                  onBack: () => context.go('/messagerie'),
                  onSend: () => _send(conversation.id),
                ),
              );

    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      appBar: AppBar(
        backgroundColor: SoutraliColors.deepGreen,
        foregroundColor: Colors.white,
        title: const Text('Messagerie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => (wide && selectedId == null) || context.canPop()
              ? (context.canPop() ? context.pop() : context.go('/'))
              : context.go('/'),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : !wide && selectedId != null
              ? threadPanel
              : Row(
                  children: [
                    SizedBox(width: wide ? 320 : double.infinity, child: listPanel),
                    if (wide) ...[
                      const VerticalDivider(width: 1, color: SoutraliColors.border),
                      Expanded(child: threadPanel),
                    ],
                  ],
                ),
    );
  }
}

class _ThreadView extends StatelessWidget {
  const _ThreadView({
    required this.conversation,
    required this.controller,
    required this.sending,
    required this.wide,
    required this.onBack,
    required this.onSend,
  });

  final ConversationThread conversation;
  final TextEditingController controller;
  final bool sending;
  final bool wide;
  final VoidCallback onBack;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: SoutraliColors.border)),
          ),
          child: Row(
            children: [
              if (!wide)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Conversations',
                  onPressed: onBack,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.participantName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go('/listing/${conversation.listingId}'),
                      child: Text(
                        'Annonce : ${conversation.listingTitle}',
                        style: const TextStyle(
                          color: SoutraliColors.orangeText,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: conversation.messages.isEmpty
              ? const Center(
                  child: Text('Aucun message. Donnez le premier coup de fil !',
                      style: TextStyle(color: SoutraliColors.muted)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation.messages.length,
                  itemBuilder: (context, index) {
                    final message = conversation.messages[index];
                    final mine = message.isMine;

                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: mine ? SoutraliColors.paleGreen : Colors.white,
                          border: Border.all(color: SoutraliColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.body),
                            if (message.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d MMM HH:mm', 'fr').format(
                                  DateTime.parse(message.createdAt!).toLocal(),
                                ),
                                style: const TextStyle(fontSize: 11, color: SoutraliColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: SoutraliColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'Écrire un message…',
                    counterText: '',
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: SoutraliColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                ),
                tooltip: 'Envoyer',
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
