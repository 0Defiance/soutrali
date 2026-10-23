import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/soutrali_theme.dart';
import '../discover/references_repository.dart';
import 'auth_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final communes = ref.watch(communesProvider);

    return Scaffold(
      backgroundColor: SoutraliColors.ivory,
      appBar: AppBar(
        backgroundColor: SoutraliColors.deepGreen,
        foregroundColor: Colors.white,
        title: const Text('Créer un compte'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: SoutraliColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Rejoindre Soutrali', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    const Text(
                      'Un e-mail et un mot de passe : vous pourrez publier, contacter et signaler.',
                      style: TextStyle(color: SoutraliColors.muted),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom affiché',
                        hintText: 'Ex. Awa Koné',
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
                      decoration: const InputDecoration(labelText: 'E-mail'),
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
                      decoration: const InputDecoration(labelText: 'Commune (facultatif)'),
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
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe (8 caractères minimum)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Mot de passe obligatoire.';
                        if (value.length < 8) return 'Au moins 8 caractères.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                      validator: (value) {
                        if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas.';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: SoutraliColors.orangeText)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: SoutraliColors.orange,
                        foregroundColor: SoutraliColors.ink,
                        minimumSize: const Size(44, 48),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Créer mon compte'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Déjà un compte ? Se connecter'),
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
