import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/soutrali_theme.dart';
import '../auth/auth_repository.dart';
import 'account_repository.dart';

/// Section « Canaux de contact » du profil (F-02) : chaque canal porte
/// sa propre visibilité ; seul un canal marqué visible est montré aux
/// membres connectés sur le détail de l’annonce (F-06).
class ContactChannelsSection extends ConsumerWidget {
  const ContactChannelsSection({super.key});

  static const typeLabels = {
    'TELEPHONE': 'Téléphone',
    'EMAIL': 'E-mail',
    'WHATSAPP': 'WhatsApp',
  };

  static IconData iconFor(String type) => switch (type) {
        'EMAIL' => Icons.mail_outline,
        'WHATSAPP' => Icons.chat_outlined,
        _ => Icons.phone_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.value == null) {
      return const SizedBox.shrink();
    }

    final channelsAsync = ref.watch(myChannelsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Canaux de contact', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () => _editChannel(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const Text(
          'Vos coordonnées ne sont montrées qu’aux membres connectés, '
          'uniquement si vous les rendez visibles. La messagerie interne reste le canal principal.',
          style: TextStyle(color: SoutraliColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        channelsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (error, stack) => const Text(
            'Impossible de charger vos canaux de contact.',
            style: TextStyle(color: SoutraliColors.orangeText, fontSize: 13),
          ),
          data: (channels) => channels.isEmpty
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Aucun canal renseigné.', style: TextStyle(color: SoutraliColors.muted)),
                )
              : Column(
                  children: [
                    for (final channel in channels)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(iconFor(channel.type), size: 18, color: SoutraliColors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${channel.label} : ${channel.value}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: channel.visibleToMembers ? SoutraliColors.paleGreen : SoutraliColors.paleOrange,
                                border: Border.all(color: SoutraliColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                channel.visibleToMembers ? 'Visible' : 'Masqué',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editChannel(context, ref, channel),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deleteChannel(context, ref, channel),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _editChannel(BuildContext context, WidgetRef ref, ContactChannel? channel) async {
    final saved = await showDialog<(String, String, bool)>(
      context: context,
      builder: (dialogContext) => _ChannelDialog(existing: channel),
    );

    if (saved == null || !context.mounted) return;

    final (type, value, visible) = saved;

    try {
      await ref.read(accountRepositoryProvider).saveChannel(
            type: type,
            value: value,
            visibleToMembers: visible,
          );
      ref.invalidate(myChannelsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canal de contact enregistré.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }

  Future<void> _deleteChannel(BuildContext context, WidgetRef ref, ContactChannel channel) async {
    final channelId = channel.id;
    if (channelId == null) return;

    try {
      await ref.read(accountRepositoryProvider).deleteChannel(channelId);
      ref.invalidate(myChannelsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Canal ${channel.label} supprimé.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }
}

class _ChannelDialog extends StatefulWidget {
  const _ChannelDialog({this.existing});

  final ContactChannel? existing;

  @override
  State<_ChannelDialog> createState() => _ChannelDialogState();
}

class _ChannelDialogState extends State<_ChannelDialog> {
  late String _type;
  late final TextEditingController _value;
  late bool _visible;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? 'TELEPHONE';
    _value = TextEditingController(text: widget.existing?.value ?? '');
    _visible = widget.existing?.visibleToMembers ?? false;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _value.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Indiquez la valeur du canal.');
      return;
    }

    if (_type != 'EMAIL' && value.length < 8) {
      setState(() => _error = 'Saisissez un numéro complet (8 chiffres minimum).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    if (!mounted) return;
    Navigator.pop(context, (_type, value, _visible));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.contact_phone_outlined, color: SoutraliColors.green),
      title: Text(widget.existing == null ? 'Ajouter un canal' : 'Modifier le canal'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type de canal'),
              items: [
                for (final entry in ContactChannelsSection.typeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: widget.existing == null
                  ? (value) => setState(() => _type = value ?? 'TELEPHONE')
                  : null,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _value,
              keyboardType: _type == 'EMAIL' ? TextInputType.emailAddress : TextInputType.phone,
              maxLength: 190,
              decoration: InputDecoration(
                labelText: _type == 'EMAIL' ? 'Adresse e-mail' : 'Numéro',
                hintText: _type == 'EMAIL' ? 'Ex. contact@exemple.net' : 'Ex. +225 07 00 00 00 00',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Visible par les membres connectés'),
              subtitle: const Text(
                'Masqué par défaut : seule la messagerie interne est proposée.',
                style: TextStyle(fontSize: 13),
              ),
              value: _visible,
              onChanged: (value) => setState(() => _visible = value),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13)),
          ],
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
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
