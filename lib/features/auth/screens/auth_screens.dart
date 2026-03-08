import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';
import 'package:nerpa_academy/data/models/models.dart';
import 'package:nerpa_academy/data/repositories/content_repository.dart';
import 'package:nerpa_academy/shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

// ─── Welcome Screen ──────────────────────────────────────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                AppStrings.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                AppStrings.welcomeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withOpacity(0.75),
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              NerpaButton(
                label: AppStrings.login,
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: AppDimens.paddingM),
              NerpaButton(
                label: AppStrings.signUp,
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
        ),
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
                    Text(
                      AppStrings.login,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(hintText: AppStrings.email),
                      validator: (v) {
                        if (v == null || v.isEmpty || !v.contains('@')) {
                          return AppStrings.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: AppStrings.password,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return AppStrings.weakPassword;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    _GoogleButton(),
                    const SizedBox(height: AppDimens.paddingXL),
                    NerpaButton(
                      label: AppStrings.login,
                      loading: loading,
                      onPressed: loading ? null : _submit,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.pop();
                          context.push('/signup/step1');
                        },
                        child: const Text("Don't have an account? Sign Up"),
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
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Step 1 of 2'),
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
              Text(
                AppStrings.signUp,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppDimens.paddingXL),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: AppStrings.email),
                validator: (v) {
                  if (v == null || !v.contains('@')) {
                    return AppStrings.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.paddingM),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: AppStrings.password,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    icon: Icon(_obscurePass
                        ? Icons.visibility_off
                        : Icons.visibility),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return AppStrings.weakPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.paddingM),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: AppStrings.confirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                  ),
                ),
                validator: (v) {
                  if (v != _passCtrl.text) {
                    return AppStrings.passwordsMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.paddingM),
              _GoogleButton(),
              const SizedBox(height: AppDimens.paddingXL),
              NerpaButton(
                label: AppStrings.next,
                onPressed: _next,
              ),
              const SizedBox(height: AppDimens.paddingM),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.pop();
                    context.push('/login');
                  },
                  child: const Text('Already have an account? Log In'),
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

  const SignUpStep2Screen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<SignUpStep2Screen> createState() => _SignUpStep2ScreenState();
}

class _SignUpStep2ScreenState extends State<SignUpStep2Screen> {
  final Set<String> _selected = {};
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
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _loading = false;
        });
      }
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
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectSubject)),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthSignUpRequested(
          email: widget.email,
          password: widget.password,
          subjectIds: _selected.toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: const Text('Step 2 of 2'),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (ctx, state) {
            final processing = state is AuthLoading;
            return Padding(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.chooseSubjects,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  Text(
                    'Selected subjects will be highlighted.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingXL),
                  if (_loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.skyBlue),
                      ),
                    )
                  else if (_error != null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: AppDimens.paddingM),
                            Text('Could not load subjects.\nCheck your connection.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: AppDimens.paddingM),
                            NerpaButton(
                              label: 'Retry',
                              onPressed: _loadSubjects,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _subjects.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppDimens.paddingM),
                        itemBuilder: (_, i) {
                          final s = _subjects[i];
                          return SubjectCard(
                            emoji: s.emoji,
                            title: s.title,
                            lessonCount: s.lessonCount,
                            selected: _selected.contains(s.id),
                            onTap: () => _toggle(s.id),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppDimens.paddingM),
                  NerpaButton(
                    label: AppStrings.continueText,
                    loading: processing,
                    onPressed: processing ? null : _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () =>
          context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
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
              child: Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.skyBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            AppStrings.signInWithGoogle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
