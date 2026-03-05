import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          context.go(_tabs[i]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Study',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, authState) {
        final user =
            authState is AuthAuthenticated ? authState.user : null;

        return BlocBuilder<LessonBloc, LessonState>(
          builder: (ctx, state) {
            // Trigger load only when the bloc is idle
            if (state is LessonInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ctx.read<LessonBloc>().add(
                      user != null && user.selectedSubjectIds.isNotEmpty
                          ? LoadSubjects(user.selectedSubjectIds)
                          : LoadAllSubjects(),
                    );
              });
            }

            if (state is LessonLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.skyBlue),
                ),
              );
            }

            final subjects =
                state is SubjectsLoaded ? state.subjects : <SubjectModel>[];

            return Scaffold(
              body: SafeArea(
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
                                        'Hi${user?.displayName != null ? ', ${user!.displayName}' : ''}! 👋',
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .headlineLarge,
                                      ),
                                      const SizedBox(height: AppDimens.paddingXS),
                                      Text(
                                        'What are we learning today?',
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
                              AppStrings.mySubjects,
                              style: Theme.of(ctx).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (subjects.isEmpty && state is! LessonLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NerpaMascot(size: 80),
                              SizedBox(height: AppDimens.paddingM),
                              Text(
                                'No subjects yet.\nCheck your profile!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
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
                                title: subjects[i].title,
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
  @override
  void initState() {
    super.initState();
    // Always dispatch LoadLessons — the BLoC may hold stale state
    // from the home screen (SubjectsLoaded), so we must force a reload.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonBloc>().add(LoadLessons(widget.subjectId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonBloc, LessonState>(
      builder: (ctx, state) {
        // Loading
        if (state is LessonInitial || state is LessonLoading) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () {
                ctx.read<LessonBloc>().add(ResetQuiz());
                context.pop();
              }),
              title: const Text('Lessons'),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.skyBlue),
            ),
          );
        }

        // Success
        if (state is LessonsLoaded) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () {
                ctx.read<LessonBloc>().add(ResetQuiz());
                context.pop();
              }),
              title: Text(state.subject.title),
            ),
            body: state.lessons.isEmpty
                ? const Center(
                    child: Text(
                      'No lessons available yet.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
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
                          ctx.read<LessonBloc>().add(LoadQuiz(lessonId: lesson.id, subjectId: state.subject.id));
                          context.push('/lesson/${state.subject.id}/${lesson.id}');
                        },
                      );
                    },
                  ),
          );
        }

        // Error
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
                  state is LessonError
                      ? state.message
                      : AppStrings.unknownError,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.paddingL),
                ElevatedButton(
                  onPressed: () => ctx
                      .read<LessonBloc>()
                      .add(LoadLessons(widget.subjectId)),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
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
