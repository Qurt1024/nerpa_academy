import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nerpa_academy/data/models/models.dart';
import 'package:nerpa_academy/data/repositories/content_repository.dart';


// ─── Events ──────────────────────────────────────────────────────────────────

abstract class LessonEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSubjects extends LessonEvent {
  final List<String> subjectIds;
  LoadSubjects(this.subjectIds);
  @override
  List<Object?> get props => [subjectIds];
}

class LoadAllSubjects extends LessonEvent {}

class LoadLessons extends LessonEvent {
  final String subjectId;
  LoadLessons(this.subjectId);
  @override
  List<Object?> get props => [subjectId];
}

class LoadQuiz extends LessonEvent {
  final String lessonId;
  final String subjectId;
  LoadQuiz({required this.lessonId, required this.subjectId});
  @override
  List<Object?> get props => [lessonId, subjectId];
}

class AnswerQuestion extends LessonEvent {
  final String answer;
  AnswerQuestion(this.answer);
  @override
  List<Object?> get props => [answer];
}

class NextQuestion extends LessonEvent {}

class StartQuiz extends LessonEvent {}

class ResetQuiz extends LessonEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class LessonState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LessonInitial extends LessonState {}

class LessonLoading extends LessonState {}

class SubjectsLoaded extends LessonState {
  final List<SubjectModel> subjects;
  SubjectsLoaded(this.subjects);
  @override
  List<Object?> get props => [subjects];
}

class LessonsLoaded extends LessonState {
  final SubjectModel subject;
  final List<LessonModel> lessons;
  LessonsLoaded({required this.subject, required this.lessons});
  @override
  List<Object?> get props => [subject, lessons];
}

class TheoryScreen extends LessonState {
  final LessonModel lesson;
  final List<QuestionModel> questions;
  TheoryScreen({required this.lesson, required this.questions});
  @override
  List<Object?> get props => [lesson, questions];
}

enum AnswerStatus { idle, correct, incorrect }

class QuizInProgress extends LessonState {
  final LessonModel lesson;
  final List<QuestionModel> questions;
  final int currentIndex;
  final int hearts; // max 3
  final AnswerStatus answerStatus;
  final String? selectedAnswer;
  final int correctCount;

  QuizInProgress({
    required this.lesson,
    required this.questions,
    required this.currentIndex,
    required this.hearts,
    required this.answerStatus,
    this.selectedAnswer,
    required this.correctCount,
  });

  QuestionModel get currentQuestion => questions[currentIndex];
  bool get isLast => currentIndex >= questions.length - 1;

  @override
  List<Object?> get props => [
        lesson,
        questions,
        currentIndex,
        hearts,
        answerStatus,
        selectedAnswer,
        correctCount,
      ];
}

class QuizFinished extends LessonState {
  final LessonModel lesson;
  final int correctCount;
  final int totalCount;
  final int hearts;

  QuizFinished({
    required this.lesson,
    required this.correctCount,
    required this.totalCount,
    required this.hearts,
  });

  double get score => totalCount == 0 ? 0 : correctCount / totalCount;

  String get grade {
    if (score >= 0.9) return '5';
    if (score >= 0.7) return '4';
    if (score >= 0.5) return '3';
    return '2';
  }

  @override
  List<Object?> get props => [lesson, correctCount, totalCount, hearts];
}

class LessonError extends LessonState {
  final String message;
  LessonError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final ContentRepository _repo;
  static const int maxHearts = 3;

  LessonBloc(this._repo) : super(LessonInitial()) {
    on<LoadSubjects>(_onLoadSubjects);
    on<LoadAllSubjects>(_onLoadAllSubjects);
    on<LoadLessons>(_onLoadLessons);
    on<LoadQuiz>(_onLoadQuiz);
    on<AnswerQuestion>(_onAnswer);
    on<NextQuestion>(_onNext);
    on<StartQuiz>(_onStartQuiz);
    on<ResetQuiz>(_onReset);
  }

  Future<void> _onLoadSubjects(
      LoadSubjects event, Emitter<LessonState> emit) async {
    emit(LessonLoading());
    try {
      final subjects =
          await _repo.fetchSubjectsByIds(event.subjectIds);
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  Future<void> _onLoadAllSubjects(
      LoadAllSubjects event, Emitter<LessonState> emit) async {
    emit(LessonLoading());
    try {
      final subjects = await _repo.fetchAllSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  Future<void> _onLoadLessons(
      LoadLessons event, Emitter<LessonState> emit) async {
    emit(LessonLoading());
    try {
      final subjects =
          await _repo.fetchSubjectsByIds([event.subjectId]);
      final lessons =
          await _repo.fetchLessonsForSubject(event.subjectId);
      emit(LessonsLoaded(
          subject: subjects.first, lessons: lessons));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  Future<void> _onLoadQuiz(
      LoadQuiz event, Emitter<LessonState> emit) async {
    emit(LessonLoading());
    try {
      final lesson = await _repo.fetchLesson(event.lessonId, event.subjectId);
      if (lesson == null) {
        emit(LessonError('Урок не найден'));
        return;
      }
      final questions =
          await _repo.fetchQuestionsForLesson(event.lessonId, event.subjectId);

      if (lesson.hasTheory) {
        emit(TheoryScreen(lesson: lesson, questions: questions));
      } else {
        emit(QuizInProgress(
          lesson: lesson,
          questions: questions,
          currentIndex: 0,
          hearts: maxHearts,
          answerStatus: AnswerStatus.idle,
          correctCount: 0,
        ));
      }
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }

  void _onAnswer(
      AnswerQuestion event, Emitter<LessonState> emit) {
    final s = state;
    if (s is! QuizInProgress) return;
    if (s.answerStatus != AnswerStatus.idle) return;

    final isCorrect = s.currentQuestion.checkAnswer(event.answer);
    final newHearts = isCorrect ? s.hearts : (s.hearts - 1).clamp(0, maxHearts);
    final newCorrect = isCorrect ? s.correctCount + 1 : s.correctCount;

    emit(QuizInProgress(
      lesson: s.lesson,
      questions: s.questions,
      currentIndex: s.currentIndex,
      hearts: newHearts,
      answerStatus:
          isCorrect ? AnswerStatus.correct : AnswerStatus.incorrect,
      selectedAnswer: event.answer,
      correctCount: newCorrect,
    ));
  }

  void _onStartQuiz(StartQuiz event, Emitter<LessonState> emit) {
    final s = state;
    if (s is! TheoryScreen) return;
    emit(QuizInProgress(
      lesson: s.lesson,
      questions: s.questions,
      currentIndex: 0,
      hearts: maxHearts,
      answerStatus: AnswerStatus.idle,
      correctCount: 0,
    ));
  }

  void _onNext(NextQuestion event, Emitter<LessonState> emit) {
    final s = state;
    if (s is! QuizInProgress) return;

    if (s.isLast || s.hearts == 0) {
      emit(QuizFinished(
        lesson: s.lesson,
        correctCount: s.correctCount,
        totalCount: s.questions.length,
        hearts: s.hearts,
      ));
    } else {
      emit(QuizInProgress(
        lesson: s.lesson,
        questions: s.questions,
        currentIndex: s.currentIndex + 1,
        hearts: s.hearts,
        answerStatus: AnswerStatus.idle,
        correctCount: s.correctCount,
      ));
    }
  }

  void _onReset(ResetQuiz event, Emitter<LessonState> emit) {
    emit(LessonInitial());
  }
}
