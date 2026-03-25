import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';
import 'package:nerpa_academy/core/l10n/app_localizations.dart';
import 'package:nerpa_academy/core/l10n/language_cubit.dart';
import 'package:nerpa_academy/data/models/models.dart';
import 'package:nerpa_academy/data/repositories/auth_repository.dart';
import 'package:nerpa_academy/features/auth/bloc/auth_bloc.dart';
import 'package:nerpa_academy/shared/widgets/shared_widgets.dart';
import '../bloc/lesson_bloc.dart';

// ─── Theory Screen ────────────────────────────────────────────────────────────

class TheoryScreenWidget extends StatelessWidget {
  final LessonModel lesson;
  final List<QuestionModel> questions;
  final String subjectId;

  const TheoryScreenWidget({
    super.key,
    required this.lesson,
    required this.questions,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () {
          // Use the explicitly passed subjectId — lesson.subjectId can be
          // empty if Firestore omits that field.
          final langCode = context.read<LanguageCubit>().state.code;
          context.read<LessonBloc>().add(
                LoadLessons(subjectId, langCode: langCode),
              );
          context.pop();
        }),
        title: Text(l10n.tr(en: 'Theory', ru: 'Теория', kz: 'Теория')),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  if (lesson.imageUrl != null && lesson.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      child: Image.network(
                        lesson.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _TheoryPlaceholder(),
                      ),
                    )
                  else
                    _TheoryPlaceholder(),
                  const SizedBox(height: AppDimens.paddingL),
                  if (lesson.theoryText != null && lesson.theoryText!.isNotEmpty)
                    Text(
                      lesson.theoryText!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.7),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: NerpaButton(
              label: l10n.startLesson,
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                context.read<LessonBloc>().add(StartQuiz());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TheoryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.skyBlueSurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      child: const Center(child: NerpaMascot(size: 120)),
    );
  }
}

// ─── Question Image (with Nerpa fallback) ─────────────────────────────────────
// Shows the question's image if one exists; falls back to the nerpa mascot
// which changes expression based on the current answer status.

class _QuestionImage extends StatelessWidget {
  final String? imageUrl;
  final AnswerStatus answerStatus;

  const _QuestionImage({required this.imageUrl, required this.answerStatus});

  String get _expression {
    switch (answerStatus) {
      case AnswerStatus.correct:   return 'happy';
      case AnswerStatus.incorrect: return 'sad';
      case AnswerStatus.idle:      return 'default';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Image.network(
          imageUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          // On load error fall back to mascot so the quiz never breaks
          errorBuilder: (_, __, ___) => _NerpaMascotBox(expression: _expression),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.skyBlue,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    // No image — show the nerpa mascot as default
    return _NerpaMascotBox(expression: _expression);
  }
}

class _NerpaMascotBox extends StatelessWidget {
  final String expression;
  const _NerpaMascotBox({required this.expression});

  @override
  Widget build(BuildContext context) {
    return NerpaMascot(size: 100, expression: expression);
  }
}

// ─── Quiz Screen ─────────────────────────────────────────────────────────────

class QuizScreenWidget extends StatefulWidget {
  final String subjectId;
  const QuizScreenWidget({super.key, required this.subjectId});

  @override
  State<QuizScreenWidget> createState() => _QuizScreenWidgetState();
}

class _QuizScreenWidgetState extends State<QuizScreenWidget> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LessonBloc, LessonState>(
      listener: (ctx, state) {
        if (state is QuizFinished) {
          context.pushReplacement('/results/${widget.subjectId}');
        }
      },
      builder: (ctx, state) {
        if (state is TheoryScreen) {
          return TheoryScreenWidget(
            lesson: state.lesson,
            questions: state.questions,
            subjectId: widget.subjectId,
          );
        }

        if (state is LessonLoading || state is LessonInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.skyBlue),
            ),
          );
        }

        if (state is! QuizInProgress) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () {
                final langCode = context.read<LanguageCubit>().state.code;
                context.read<LessonBloc>().add(
                      LoadLessons(widget.subjectId, langCode: langCode),
                    );
                context.pop();
              }),
            ),
            body: Center(
              child: Text(
                state is LessonError ? state.message : AppStrings.unknownError,
              ),
            ),
          );
        }

        final q = state.currentQuestion;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () {
              // Use widget.subjectId (from route params) — state.lesson.subjectId
              // can be empty if Firestore omits that field.
              final langCode = context.read<LanguageCubit>().state.code;
              context.read<LessonBloc>().add(
                    LoadLessons(widget.subjectId, langCode: langCode),
                  );
              context.pop();
            }),
            title: Row(
              children: [
                Expanded(
                  child: QuizProgressBar(
                    current: state.currentIndex + 1,
                    total: state.questions.length,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                HeartBar(hearts: state.hearts),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimens.paddingM),
                      _QuestionImage(
                        imageUrl: q.imageUrl,
                        answerStatus: state.answerStatus,
                      ),
                      const SizedBox(height: AppDimens.paddingL),
                      // Question card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimens.paddingL),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusXL),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          q.questionText,
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppDimens.paddingXL),
                      if (q.type == QuestionType.multipleChoice)
                        ..._buildMCQ(context, state, q)
                      else
                        _buildFreeInput(context, state),
                    ],
                  ),
                ),
              ),
              if (state.answerStatus != AnswerStatus.idle)
                _AnswerFeedbackBar(
                  isCorrect: state.answerStatus == AnswerStatus.correct,
                  correctAnswer: q.correctAnswer,
                  onNext: () {
                    _inputCtrl.clear();
                    ctx.read<LessonBloc>().add(NextQuestion());
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMCQ(
      BuildContext context, QuizInProgress state, QuestionModel q) {
    return q.options.map((option) {
      Color bgColor = AppColors.white;
      Color borderColor = AppColors.cardBorder;
      Color textColor = AppColors.textPrimary;

      if (state.answerStatus != AnswerStatus.idle) {
        final isCorrectOption = q.checkAnswer(option);
        final isSelected = state.selectedAnswer == option;
        if (isCorrectOption) {
          bgColor = AppColors.answerCorrect.withOpacity(0.15);
          borderColor = AppColors.answerCorrect;
          textColor = AppColors.answerCorrect;
        } else if (isSelected) {
          bgColor = AppColors.answerWrong.withOpacity(0.1);
          borderColor = AppColors.answerWrong;
          textColor = AppColors.answerWrong;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
        child: AnimatedContainer(
          duration: AppDimens.animNormal,
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              onTap: state.answerStatus == AnswerStatus.idle
                  ? () => context
                      .read<LessonBloc>()
                      .add(AnswerQuestion(option))
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingL,
                  vertical: AppDimens.paddingM + 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFreeInput(BuildContext context, QuizInProgress state) {
    return Column(
      children: [
        TextField(
          controller: _inputCtrl,
          enabled: state.answerStatus == AnswerStatus.idle,
          decoration: const InputDecoration(
            hintText: AppStrings.yourAnswer,
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              context
                  .read<LessonBloc>()
                  .add(AnswerQuestion(v.trim()));
            }
          },
        ),
        const SizedBox(height: AppDimens.paddingL),
        if (state.answerStatus == AnswerStatus.idle)
          NerpaButton(
            label: context.l10n.nextQuestion,
            onPressed: _inputCtrl.text.trim().isEmpty
                ? null
                : () => context
                    .read<LessonBloc>()
                    .add(AnswerQuestion(_inputCtrl.text.trim())),
          ),
      ],
    );
  }
}

// ─── Answer Feedback Banner ───────────────────────────────────────────────────

class _AnswerFeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final VoidCallback onNext;

  const _AnswerFeedbackBar({
    required this.isCorrect,
    required this.correctAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color =
        isCorrect ? AppColors.answerCorrect : AppColors.answerWrong;
    return AnimatedContainer(
      duration: AppDimens.animNormal,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingL,
        AppDimens.paddingM,
        AppDimens.paddingL,
        AppDimens.paddingXL,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCorrect ? l10n.correct : l10n.incorrect,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                if (!isCorrect)
                  Text(
                    '${l10n.tr(en: 'Correct answer', ru: 'Правильный ответ', kz: 'Дұрыс жауап')}: $correctAnswer',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(80, 44),
            ),
            child: Text(l10n.nextQuestion),
          ),
        ],
      ),
    );
  }
}

// ─── Results Screen ───────────────────────────────────────────────────────────

class ResultsScreen extends StatefulWidget {
  final String subjectId;
  const ResultsScreen({super.key, required this.subjectId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _scoreSaved = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (_, lang) {
        final l10n = AppLocalizations(lang);
        return BlocBuilder<LessonBloc, LessonState>(
          builder: (ctx, state) {
            if (state is! QuizFinished) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.skyBlue),
                ),
              );
            }

            // Save score once
            if (!_scoreSaved) {
              _scoreSaved = true;
              final authState = ctx.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                final scoreToAdd = state.correctCount * 10;
                AuthRepository().addCompletedLesson(
                  authState.user.uid,
                  state.lesson.id,
                  scoreToAdd,
                ).then((_) {
                  ctx.read<AuthBloc>().add(AuthUserRefreshed());
                });
              }
            }

            final emoji =
                state.grade == '5' || state.grade == '4' ? '🎉' : '📚';

            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Column(
                    children: [
                      const Spacer(),
                      NerpaMascot(
                        size: 140,
                        expression: state.score >= 0.5 ? 'happy' : 'sad',
                      ),
                      const SizedBox(height: AppDimens.paddingL),
                      Text(
                        '$emoji ${l10n.lessonResults}',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.paddingXL),
                      _StatCard(
                        label: l10n.tr(en: 'Correct answers', ru: 'Правильные ответы', kz: 'Дұрыс жауаптар'),
                        value: '${state.correctCount} / ${state.totalCount}',
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      _StatCard(
                        label: l10n.tr(en: 'Grade', ru: 'Оценка', kz: 'Баға'),
                        value: state.grade,
                        highlight: true,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        children: [
                          Text(
                            l10n.tr(en: 'Lives remaining: ', ru: 'Осталось жизней: ', kz: 'Қалған өмірлер: '),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          HeartBar(hearts: state.hearts),
                        ],
                      ),
                      const Spacer(),
                      NerpaButton(
                        label: l10n.tr(en: 'Back to Lessons', ru: 'К урокам', kz: 'Сабақтарға'),
                        onPressed: () {
                          ctx.read<LessonBloc>().add(ResetQuiz());
                          context.go('/home');
                        },
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      NerpaButton(
                        label: l10n.tr(en: 'Try Again', ru: 'Попробовать снова', kz: 'Қайта көру'),
                        outlined: true,
                        onPressed: () {
                          final lessonId = state.lesson.id;
                          ctx.read<LessonBloc>().add(LoadQuiz(
                              lessonId: lessonId,
                              subjectId: widget.subjectId,
                              langCode: lang.code));
                          context.pushReplacement('/lesson/${widget.subjectId}/$lessonId');
                        },
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
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingL),
      decoration: BoxDecoration(
        color:
            highlight ? AppColors.skyBlueSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color:
              highlight ? AppColors.skyBlue : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.skyBlue
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
