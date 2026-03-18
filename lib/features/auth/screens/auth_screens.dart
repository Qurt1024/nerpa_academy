import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';
import 'package:nerpa_academy/core/l10n/app_localizations.dart';
import 'package:nerpa_academy/core/l10n/language_cubit.dart';
import 'package:nerpa_academy/data/models/models.dart';
import 'package:nerpa_academy/data/repositories/content_repository.dart';
import 'package:nerpa_academy/shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

// ─── Welcome Screen ──────────────────────────────────────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const AppIcon(size: 160),
              const SizedBox(height: AppDimens.paddingXL),
              Text(
                l10n.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                l10n.welcomeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withOpacity(0.75),
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              NerpaButton(label: l10n.login, onPressed: () => context.push('/login')),
              const SizedBox(height: AppDimens.paddingM),
              NerpaButton(
                label: l10n.signUp,
                outlined: true,
                onPressed: () => context.push('/signup/step1'),
              ),
              const SizedBox(height: AppDimens.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Screen ────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthNeedsSubjectSelection) {
          context.go('/select-subjects');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (ctx, state) {
            final loading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: AppIcon(size: 80)),
                    const SizedBox(height: AppDimens.paddingL),
                    Text(l10n.login, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: AppDimens.paddingXL),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(hintText: l10n.email),
                      validator: (v) {
                        if (v == null || v.isEmpty || !v.contains('@')) return l10n.invalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: l10n.password,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) return l10n.weakPassword;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    _GoogleButton(),
                    const SizedBox(height: AppDimens.paddingXL),
                    NerpaButton(label: l10n.login, loading: loading, onPressed: loading ? null : _submit),
                    const SizedBox(height: AppDimens.paddingM),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.pop();
                          context.push('/signup/step1');
                        },
                        child: Text(l10n.dontHaveAccount),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Sign Up Step 1 ──────────────────────────────────────────────────────────

class SignUpStep1Screen extends StatefulWidget {
  const SignUpStep1Screen({super.key});

  @override
  State<SignUpStep1Screen> createState() => _SignUpStep1ScreenState();
}

class _SignUpStep1ScreenState extends State<SignUpStep1Screen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.push('/signup/step2', extra: {
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(l10n.step1of2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppIcon(size: 80)),
              const SizedBox(height: AppDimens.paddingL),
              Text(l10n.signUp, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: AppDimens.paddingXL),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(hintText: l10n.email),
                validator: (v) {
                  if (v == null || !v.contains('@')) return l10n.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.paddingM),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: l10n.password,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return l10n.weakPassword;
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.paddingM),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: l10n.confirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (v) {
                  if (v != _passCtrl.text) return l10n.passwordsMismatch;
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.paddingM),
              _GoogleButton(),
              const SizedBox(height: AppDimens.paddingXL),
              NerpaButton(label: l10n.next, onPressed: _next),
              const SizedBox(height: AppDimens.paddingM),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.pop();
                    context.push('/login');
                  },
                  child: Text(l10n.alreadyHaveAccount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sign Up Step 2 ──────────────────────────────────────────────────────────

class SignUpStep2Screen extends StatefulWidget {
  final String email;
  final String password;

  const SignUpStep2Screen({super.key, required this.email, required this.password});

  @override
  State<SignUpStep2Screen> createState() => _SignUpStep2ScreenState();
}

class _SignUpStep2ScreenState extends State<SignUpStep2Screen> {
  final Set<String> _selected = {};
  String? _selectedLanguageSubjectId;
  List<SubjectModel> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final repo = ContentRepository();
      final subjects = await repo.fetchAllSubjects();
      if (mounted) setState(() { _subjects = subjects; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _submit() {
    final l10n = context.l10n;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectSubject)),
      );
      return;
    }
    final allSelected = [
      ..._selected,
      if (_selectedLanguageSubjectId != null) _selectedLanguageSubjectId!,
    ];
    context.read<AuthBloc>().add(AuthSignUpRequested(
          email: widget.email,
          password: widget.password,
          subjectIds: allSelected,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) context.go('/home');
        if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      // BlocBuilder on LanguageCubit so the whole screen rebuilds when
      // the user picks a different app language on this screen.
      child: BlocBuilder<LanguageCubit, AppLanguage>(
        builder: (ctx, appLang) {
          final l10n = AppLocalizations(appLang);
          final learnableLanguages = appLang.learnable;
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.pop()),
              title: Text(l10n.step2of2),
            ),
            body: BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, state) {
                final processing = state is AuthLoading;
                return Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Language picker ────────────────────────────────
                      const _AppLanguagePicker(),
                      const SizedBox(height: AppDimens.paddingXL),
                      Text(l10n.chooseSubjects, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: AppDimens.paddingS),
                      Text(l10n.selectedHighlighted, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppDimens.paddingM),
                      if (_loading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
                        )
                      else if (_error != null)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: AppDimens.paddingM),
                                Text(l10n.couldNotLoadSubjects, textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: AppDimens.paddingM),
                                NerpaButton(label: l10n.retry, onPressed: _loadSubjects),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView(
                            children: [
                              ..._subjects
                                  .where((s) => !s.id.startsWith('language_'))
                                  .map((s) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                        child: SubjectCard(
                                          emoji: s.emoji,
                                          title: s.localTitle(appLang.code),
                                          lessonCount: s.lessonCount,
                                          selected: _selected.contains(s.id),
                                          onTap: () => _toggle(s.id),
                                        ),
                                      )),
                              if (learnableLanguages.isNotEmpty) ...[
                                const SizedBox(height: AppDimens.paddingM),
                                Text(l10n.chooseLanguageSubject,
                                    style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: AppDimens.paddingM),
                                ...learnableLanguages.map((lang) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                      child: SubjectCard(
                                        emoji: _langEmoji(lang),
                                        title: l10n.languageSubjectName(lang),
                                        lessonCount: 0,
                                        selected: _selectedLanguageSubjectId == lang.subjectId,
                                        onTap: () => setState(() {
                                          _selectedLanguageSubjectId =
                                              _selectedLanguageSubjectId == lang.subjectId
                                                  ? null
                                                  : lang.subjectId;
                                        }),
                                      ),
                                    )),
                              ],
                              const SizedBox(height: AppDimens.paddingM),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppDimens.paddingM),
                      NerpaButton(
                        label: l10n.continueText,
                        loading: processing,
                        onPressed: processing ? null : _submit,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Subject Selection Screen (for Google new users / missing subjects) ───────
// This screen is shown instead of the regular Sign Up Step 2 when a user
// authenticates via Google and has no subjects selected yet.

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final Set<String> _selected = {};
  String? _selectedLanguageSubjectId;
  List<SubjectModel> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final repo = ContentRepository();
      final subjects = await repo.fetchAllSubjects();
      if (mounted) setState(() { _subjects = subjects; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _submit() {
    final l10n = context.l10n;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectSubject)),
      );
      return;
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthNeedsSubjectSelection) return;

    final appLang = context.read<LanguageCubit>().state;
    final allSelected = [
      ..._selected,
      if (_selectedLanguageSubjectId != null) _selectedLanguageSubjectId!,
    ];

    context.read<AuthBloc>().add(AuthGoogleSubjectsSelected(
          user: authState.user,
          subjectIds: allSelected,
          appLanguage: appLang.code,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) context.go('/home');
        if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: BlocBuilder<LanguageCubit, AppLanguage>(
        builder: (ctx, appLang) {
          final l10n = AppLocalizations(appLang);
          final learnableLanguages = appLang.learnable;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.chooseSubjects)),
            body: BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, state) {
                final processing = state is AuthLoading;
                return Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Language picker ──────────────────────────────
                      const _AppLanguagePicker(),
                      const SizedBox(height: AppDimens.paddingXL),
                      Text(l10n.chooseSubjects, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: AppDimens.paddingS),
                      Text(l10n.selectedHighlighted, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppDimens.paddingM),
                      if (_loading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
                        )
                      else if (_error != null)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: AppDimens.paddingM),
                                Text(l10n.couldNotLoadSubjects, textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: AppDimens.paddingM),
                                NerpaButton(label: l10n.retry, onPressed: _loadSubjects),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView(
                            children: [
                              ..._subjects
                                  .where((s) => !s.id.startsWith('language_'))
                                  .map((s) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                        child: SubjectCard(
                                          emoji: s.emoji,
                                          title: s.localTitle(appLang.code),
                                          lessonCount: s.lessonCount,
                                          selected: _selected.contains(s.id),
                                          onTap: () => setState(() {
                                            if (_selected.contains(s.id)) {
                                              _selected.remove(s.id);
                                            } else {
                                              _selected.add(s.id);
                                            }
                                          }),
                                        ),
                                      )),
                              if (learnableLanguages.isNotEmpty) ...[
                                const SizedBox(height: AppDimens.paddingM),
                                Text(l10n.chooseLanguageSubject,
                                    style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: AppDimens.paddingM),
                                ...learnableLanguages.map((lang) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                      child: SubjectCard(
                                        emoji: _langEmoji(lang),
                                        title: l10n.languageSubjectName(lang),
                                        lessonCount: 0,
                                        selected: _selectedLanguageSubjectId == lang.subjectId,
                                        onTap: () => setState(() {
                                          _selectedLanguageSubjectId =
                                              _selectedLanguageSubjectId == lang.subjectId
                                                  ? null
                                                  : lang.subjectId;
                                        }),
                                      ),
                                    )),
                              ],
                              const SizedBox(height: AppDimens.paddingM),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppDimens.paddingM),
                      NerpaButton(
                        label: l10n.continueText,
                        loading: processing,
                        onPressed: processing ? null : _submit,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── App Language Picker (used on subject selection screens) ─────────────────
// Lets new users choose their app language before picking subjects, so that
// the "language to learn" section correctly excludes their own language.

class _AppLanguagePicker extends StatelessWidget {
  const _AppLanguagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (ctx, currentLang) {
        final l10n = AppLocalizations(currentLang);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appLanguageLabel,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppDimens.paddingS),
            Row(
              children: AppLanguage.values.map((lang) {
                final selected = lang == currentLang;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => ctx.read<LanguageCubit>().changeLanguage(lang),
                      child: AnimatedContainer(
                        duration: AppDimens.animFast,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.skyBlue : AppColors.scaffold,
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          border: Border.all(
                            color: selected ? AppColors.skyBlue : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          lang.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: selected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton(
      onPressed: () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
        ),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.skyBlue.withOpacity(0.2),
            ),
            child: const Center(
              child: Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.skyBlue)),
            ),
          ),
          const SizedBox(width: 8),
          Text(l10n.signInWithGoogle,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _langEmoji(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.english: return '🇬🇧';
    case AppLanguage.russian: return '🇷🇺';
    case AppLanguage.kazakh:  return '🇰🇿';
  }
}
