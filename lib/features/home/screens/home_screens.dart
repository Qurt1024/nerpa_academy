import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';
import 'package:nerpa_academy/core/l10n/app_localizations.dart';
import 'package:nerpa_academy/core/l10n/language_cubit.dart';
import 'package:nerpa_academy/data/models/models.dart';
import 'package:nerpa_academy/features/auth/bloc/auth_bloc.dart';
import 'package:nerpa_academy/features/lessons/bloc/lesson_bloc.dart';
import 'package:nerpa_academy/shared/widgets/shared_widgets.dart';

// ─── Main Shell (Bottom Nav) ─────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = ['/home', '/multiplayer', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BlocBuilder<LanguageCubit, AppLanguage>(
        builder: (_, __) {
          final l10n = context.l10n;
          return BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) {
              setState(() => _index = i);
              context.go(_tabs[i]);
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_rounded),
                label: l10n.study,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_alt_rounded),
                label: l10n.play,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: l10n.profile,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tracks which subject IDs were last loaded. Subject titles resolve
  // instantly via localTitle() so no reload needed on language change.
  String? _lastSubjectKey;

  void _load(BuildContext ctx) {
    final authState = ctx.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final langCode = ctx.read<LanguageCubit>().state.code;
    final subjectKey = user?.selectedSubjectIds.join(',') ?? '';

    _lastSubjectKey = subjectKey;

    ctx.read<LessonBloc>().add(
          user != null && user.selectedSubjectIds.isNotEmpty
              ? LoadSubjects(user.selectedSubjectIds, langCode: langCode)
              : LoadAllSubjects(langCode: langCode),
        );
  }

  Future<void> _refresh() async {
    _load(context);
    // Wait until loading finishes
    await context.read<LessonBloc>().stream
        .firstWhere((s) => s is SubjectsLoaded || s is LessonError);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return BlocBuilder<LanguageCubit, AppLanguage>(
          builder: (_, lang) {
            return BlocBuilder<LessonBloc, LessonState>(
              builder: (ctx, state) {
                final subjectKey = user?.selectedSubjectIds.join(',') ?? '';

                // Reload only on first load or when subject selection changes.
                // Language changes do NOT need a reload — subject titles resolve
                // instantly via localTitle(lang.code) at display time.
                final needsLoad = state is LessonInitial
                    || _lastSubjectKey != subjectKey;

                if (needsLoad && state is! LessonLoading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _load(ctx);
                  });
                }

                // Treat LessonInitial as loading so HomeScreen shows a spinner
                // (not an empty subjects list) while the reload triggered by
                // addPostFrameCallback is in flight.  This prevents the "no
                // subjects selected" flash that appeared after pressing the
                // back button on the LessonsScreen.
                if (state is LessonInitial || state is LessonLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: AppColors.skyBlue),
                    ),
                  );
                }

                final subjects =
                    state is SubjectsLoaded ? state.subjects : <SubjectModel>[];
                final l10n = AppLocalizations(lang);

                return Scaffold(
                  body: SafeArea(
                    child: RefreshIndicator(
                      color: AppColors.skyBlue,
                      onRefresh: _refresh,
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                                AppDimens.paddingL,
                                AppDimens.paddingL,
                                AppDimens.paddingL,
                                0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.hiUser(user?.displayName),
                                              style: Theme.of(ctx)
                                                  .textTheme
                                                  .headlineLarge,
                                            ),
                                            const SizedBox(height: AppDimens.paddingXS),
                                            Text(
                                              l10n.whatAreWeLearning,
                                              style: Theme.of(ctx).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const NerpaMascot(size: 72, expression: 'happy'),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimens.paddingXL),
                                  Text(
                                    l10n.mySubjects,
                                    style: Theme.of(ctx).textTheme.headlineMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (subjects.isEmpty && state is! LessonLoading)
                            SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const NerpaMascot(size: 80),
                                    const SizedBox(height: AppDimens.paddingM),
                                    Text(
                                      l10n.noSubjectsYet,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.all(AppDimens.paddingL),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppDimens.paddingM),
                                    child: SubjectCard(
                                      emoji: subjects[i].emoji,
                                      title: subjects[i].localTitle(lang.code),
                                      lessonCount: subjects[i].lessonCount,
                                      onTap: () => context
                                          .push('/lessons/${subjects[i].id}'),
                                    ),
                                  ),
                                  childCount: subjects.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Lessons List Screen ──────────────────────────────────────────────────────
// FIX: StatefulWidget so LoadLessons is always dispatched on entry,
// regardless of the bloc's current state.

class LessonsScreen extends StatefulWidget {
  final String subjectId;
  const LessonsScreen({super.key, required this.subjectId});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  String? _lastLangCode;
  bool _isNavigatingBack = false;

  void _onBack(BuildContext ctx) {
    setState(() => _isNavigatingBack = true);
    ctx.read<LessonBloc>().add(ResetQuiz());
    context.pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final langCode = context.read<LanguageCubit>().state.code;
      _lastLangCode = langCode;
      context.read<LessonBloc>().add(
          LoadLessons(widget.subjectId, langCode: langCode));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (_, lang) {
        final l10n = AppLocalizations(lang);

        // Reload lessons when language changes so titles update immediately.
        if (_lastLangCode != null && _lastLangCode != lang.code) {
          _lastLangCode = lang.code;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<LessonBloc>().add(
                  LoadLessons(widget.subjectId, langCode: lang.code));
            }
          });
        }
        return BlocBuilder<LessonBloc, LessonState>(
          builder: (ctx, state) {
            // If state got reset to LessonInitial while this screen is still
            // active (e.g. coming back from quiz), re-dispatch LoadLessons.
            // Guard: skip when navigating back so we don't overwrite the
            // LoadSubjects that HomeScreen is about to dispatch.
            if (state is LessonInitial && !_isNavigatingBack) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<LessonBloc>().add(
                      LoadLessons(widget.subjectId, langCode: lang.code));
                }
              });
            }

            if (state is LessonInitial || state is LessonLoading) {
              return Scaffold(
                appBar: AppBar(
                  leading: BackButton(onPressed: () => _onBack(ctx)),
                  title: Text(l10n.lessons),
                ),
                body: const Center(
                  child: CircularProgressIndicator(color: AppColors.skyBlue),
                ),
              );
            }

            if (state is LessonsLoaded) {
              return Scaffold(
                appBar: AppBar(
                  leading: BackButton(onPressed: () => _onBack(ctx)),
                  title: Text(state.subject.localTitle(lang.code)),
                ),
                body: state.lessons.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noLessonsAvailable,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.skyBlue,
                        onRefresh: () async {
                          ctx.read<LessonBloc>().add(LoadLessons(
                              widget.subjectId, langCode: lang.code));
                          await ctx.read<LessonBloc>().stream.firstWhere(
                              (s) => s is LessonsLoaded || s is LessonError);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppDimens.paddingL),
                          itemCount: state.lessons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppDimens.paddingM),
                          itemBuilder: (_, i) {
                            final lesson = state.lessons[i];
                            return _LessonTile(
                              number: i + 1,
                              title: lesson.title,
                              onTap: () {
                                ctx.read<LessonBloc>().add(LoadQuiz(
                                    lessonId: lesson.id,
                                    subjectId: state.subject.id,
                                    langCode: lang.code));
                                context.push('/lesson/${state.subject.id}/${lesson.id}');
                              },
                            );
                          },
                        ),
                      ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                leading: BackButton(onPressed: () => context.pop()),
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NerpaMascot(size: 80, expression: 'sad'),
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      state is LessonError ? state.message : l10n.unknownError,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingL),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () => ctx
                            .read<LessonBloc>()
                            .add(LoadLessons(widget.subjectId, langCode: lang.code)),
                        child: Text(l10n.retry),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LessonTile extends StatelessWidget {
  final int number;
  final String title;
  final VoidCallback onTap;

  const _LessonTile({
    required this.number,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.skyBlueSurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: AppColors.skyBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
