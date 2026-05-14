import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/view_models/app_session_controller.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.sessionController});

  final AppSessionController sessionController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _localError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;

    if (currentState == null || !currentState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final success = await widget.sessionController.signIn(
      usernameOrEmail: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _localError = success ? null : widget.sessionController.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _localError ?? widget.sessionController.errorMessage;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF6F8FC)),
        child: SafeArea(
          bottom: true,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _LoginFormCard(
                  formKey: _formKey,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  isSubmitting: _isSubmitting,
                  errorMessage: errorMessage,
                  onSubmit: _submit,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(88),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FurpaBrandColors.navy.withAlpha(10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Center(child: FurpaBrandLockup(scale: 1, showCaption: true)),
          const SizedBox(height: 24),
          Text(
            'Oturum Ac',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: FurpaBrandColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kullanici bilgilerinizi girin. Yetkilerinizle uyumlu ekranlar otomatik yuklenir.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: FurpaBrandColors.muted,
              height: 1.45,
            ),
          ),
          if (errorMessage != null &&
              errorMessage!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9B2B2)),
              ),
              child: Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF862424),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 18),
            child: AutofillGroup(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanici adi veya e-posta',
                        hintText: 'admin',
                      ),
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.username],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kullanici adi zorunlu.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Sifre'),
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const <String>[AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSubmit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sifre zorunlu.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: isSubmitting ? null : onSubmit,
                      icon: isSubmitting
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(isSubmitting ? 'Baglaniyor...' : 'Giris Yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Sunucu: ${AppConfig.baseUrl}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: FurpaBrandColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
