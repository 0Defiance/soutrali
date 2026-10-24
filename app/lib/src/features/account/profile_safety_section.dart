import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/soutrali_theme.dart';
import '../auth/auth_repository.dart';
import 'account_repository.dart';

/// Section « Comptes bloqués » du profil : liste les comptes que
/// l’utilisateur a bloqués (T-14) et permet de les débloquer.
class BlockedAccountsSection extends ConsumerWidget {
  const BlockedAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.value == null) {
      return const SizedBox.shrink();
    }

    final blockedAsync = ref.watch(blockedUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comptes bloqués', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'La messagerie est désactivée dans les deux sens avec ces comptes.',
          style: TextStyle(color: SoutraliColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        blockedAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (error, stack) => const Text(
            'Impossible de charger les comptes bloqués.',
            style: TextStyle(color: SoutraliColors.orangeText, fontSize: 13),
          ),
          data: (blocked) => blocked.isEmpty
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Aucun compte bloqué.',
                    style: TextStyle(color: SoutraliColors.muted),
                  ),
                )
              : Column(
                  children: [
                    for (final account in blocked)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.block, size: 18, color: SoutraliColors.muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                account.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _unblock(context, ref, account),
                              child: const Text('Débloquer'),
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

  Future<void> _unblock(BuildContext context, WidgetRef ref, BlockedUser account) async {
    try {
      await ref.read(accountRepositoryProvider).unblock(account.id);
      ref.invalidate(blockedUsersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compte ${account.displayName} débloqué.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(error))),
      );
    }
  }
}
