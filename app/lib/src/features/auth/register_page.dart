import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/soutrali_theme.dart';
import '../discover/references_repository.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';

/// Page d'inscription (D-04 validée le 22 oct. 2026 : e-mail + mot de passe).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String _communeId = '';
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            communeId: int.tryParse(_communeId),
          );

      if (!mounted) return;
      context.go('/');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Copie locale : la promotion de type ne s’applique pas aux champs.
    final error = _error;
    final communes = ref.watch(communesProvider);

    return AuthShell(
      title: 'Rejoindre Soutrali',
      subtitle: 'Un e-mail et un mot de passe : vous pourrez publier, contacter et signaler.',
      footer: TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Déjà un compte ? Se connecter'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: _decoration(
                label: 'Nom affiché',
                hint: 'Ex. Awa Koné',
                icon: Icons.person_outline,
              ),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Nom obligatoire.';
                if (name.length < 2) return 'Au moins 2 caractères.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _decoration(label: 'E-mail', icon: Icons.mail_outline),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'E-mail obligatoire.';
                if (!email.contains('@')) return 'Saisissez un e-mail valide.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _communeId,
              isExpanded: true,
              decoration: _decoration(label: 'Commune (facultatif)', icon: Icons.location_on_outlined),
              items: [
                const DropdownMenuItem(value: '', child: Text('— Choisir une commune —')),
                for (final item in communes.value ?? const <ReferenceItem>[])
                  DropdownMenuItem(value: item.id.toString(), child: Text(item.name)),
              ],
              onChanged: (value) => setState(() => _communeId = value ?? ''),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _decoration(
                label: 'Mot de passe (8 caractères minimum)',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Mot de passe obligatoire.';
                if (value.length < 8) return 'Au moins 8 caractères.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmationController,
              obscureText: _obscureConfirmation,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _decoration(
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscureConfirmation ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                  icon: Icon(_obscureConfirmation ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirmation = !_obscureConfirmation),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas.';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: error == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey<String>(error),
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: SoutraliColors.paleOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: SoutraliColors.orangeText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: const TextStyle(color: SoutraliColors.orangeText, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: SoutraliColors.orange,
                foregroundColor: SoutraliColors.ink,
                minimumSize: const Size(44, 52),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.person_add_alt_1_outlined, size: 19),
              label: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
