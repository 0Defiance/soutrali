import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/soutrali_theme.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';

/// Page de connexion (D-04 : e-mail + mot de passe).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _from {
    final value = GoRouterState.of(context).uri.queryParameters['from'];

    return value != null && value.isNotEmpty ? value : '/';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      context.go(_from);
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
    // Copie locale : la promotion de type ne s’applique pas aux champs.
    final error = _error;

    return AuthShell(
      title: 'Heureux de vous revoir',
      subtitle: 'Connectez-vous pour publier, contacter et gérer vos annonces.',
      footer: TextButton(
        onPressed: () => context.go('/register'),
        child: const Text('Pas encore de compte ? Créer un compte'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'E-mail obligatoire.';
                if (!email.contains('@')) return 'Saisissez un e-mail valide.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Mot de passe obligatoire.' : null,
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
                backgroundColor: SoutraliColors.green,
                minimumSize: const Size(44, 52),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.login_rounded, size: 19),
              label: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
