import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/language_cubit.dart';
import '../../data/models/models.dart';
import '../../data/repositories/multiplayer_repository.dart';
import '../../data/repositories/content_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/bloc/auth_bloc.dart';

// ─── Room BLoC ────────────────────────────────────────────────────────────────

abstract class RoomEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateRoomRequested extends RoomEvent {
  final String subjectId;
  final String lessonId;
  CreateRoomRequested({required this.subjectId, required this.lessonId});
}

class JoinRoomRequested extends RoomEvent {
  final String roomId;
  JoinRoomRequested(this.roomId);
}

class FindMatchRequested extends RoomEvent {
  final String subjectId;
  FindMatchRequested(this.subjectId);
}

class SetReadyRequested extends RoomEvent {
  final bool isReady;
  SetReadyRequested(this.isReady);
}

class StartGameRequested extends RoomEvent {}

class AnswerGameQuestion extends RoomEvent {
  final String answer;
  final DateTime answeredAt;
  AnswerGameQuestion({required this.answer, required this.answeredAt});
}

class AdvanceToNextQuestion extends RoomEvent {}

class LeaveRoomRequested extends RoomEvent {}

class RoomUpdated extends RoomEvent {
  final RoomModel room;
  RoomUpdated(this.room);
  @override
  List<Object?> get props => [room];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class RoomState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomWaiting extends RoomState {
  final RoomModel room;
  RoomWaiting(this.room);
  @override
  List<Object?> get props => [room];
}

class RoomPlaying extends RoomState {
  final RoomModel room;
  final List<QuestionModel> questions;
  final int currentIndex;
  final bool answered;
  final int timeLeft;
  RoomPlaying({
    required this.room,
    required this.questions,
    required this.currentIndex,
    required this.answered,
    required this.timeLeft,
  });
  @override
  List<Object?> get props => [room, questions, currentIndex, answered, timeLeft];
}

class RoomFinished extends RoomState {
  final RoomModel room;
  RoomFinished(this.room);
  @override
  List<Object?> get props => [room];
}

class RoomError extends RoomState {
  final String message;
  RoomError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final MultiplayerRepository _mpRepo;
  final ContentRepository _contentRepo;
  final String currentUid;
  final String displayName;

  StreamSubscription<RoomModel>? _roomSub;
  Timer? _timer;
  String? _currentRoomId;
  List<QuestionModel> _questions = [];
  int _timeLeft = 20;
  DateTime? _questionStartTime;
  int _timerQuestionIndex = -1;
  bool _loadingQuestions = false; // prevents concurrent fetches

  RoomBloc({
    required MultiplayerRepository mpRepo,
    required ContentRepository contentRepo,
    required this.currentUid,
    required this.displayName,
  })  : _mpRepo = mpRepo,
        _contentRepo = contentRepo,
        super(RoomInitial()) {
    on<CreateRoomRequested>(_onCreate);
    on<JoinRoomRequested>(_onJoin);
    on<FindMatchRequested>(_onFindMatch);
    on<SetReadyRequested>(_onReady);
    on<StartGameRequested>(_onStart);
    on<AnswerGameQuestion>(_onAnswer);
    on<AdvanceToNextQuestion>(_onAdvance);
    on<RoomUpdated>(_onRoomUpdated);
    on<LeaveRoomRequested>(_onLeave);
  }

  Future<void> _onCreate(CreateRoomRequested event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final roomId = await _mpRepo.createRoom(
        hostUid: currentUid,
        subjectId: event.subjectId,
        lessonId: event.lessonId,
        displayName: displayName,
      );
      _currentRoomId = roomId;
      _listenRoom(roomId);
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onJoin(JoinRoomRequested event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final room = await _mpRepo.joinRoom(
        roomId: event.roomId.toUpperCase(),
        uid: currentUid,
        displayName: displayName,
      );
      if (room == null) { emit(RoomError('Room not found')); return; }
      _currentRoomId = room.id;
      _listenRoom(room.id);
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onFindMatch(FindMatchRequested event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final roomId = await _mpRepo.findOrCreateMatchRoom(
        subjectId: event.subjectId,
        uid: currentUid,
        displayName: displayName,
      );
      _currentRoomId = roomId;
      _listenRoom(roomId);
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onReady(SetReadyRequested event, Emitter<RoomState> emit) async {
    if (_currentRoomId == null) return;
    await _mpRepo.setPlayerReady(_currentRoomId!, currentUid, event.isReady);
  }

  Future<void> _onStart(StartGameRequested event, Emitter<RoomState> emit) async {
    if (_currentRoomId == null) return;
    await _mpRepo.startGame(_currentRoomId!);
  }

  Future<void> _onAnswer(AnswerGameQuestion event, Emitter<RoomState> emit) async {
    if (state is! RoomPlaying) return;
    final s = state as RoomPlaying;
    if (s.questions.isEmpty || s.currentIndex >= s.questions.length) return;
    final q = s.questions[s.currentIndex];

    final isCorrect = q.checkAnswer(event.answer);
    if (isCorrect) {
      final elapsed = event.answeredAt.difference(_questionStartTime!).inMilliseconds;
      final bonus = (1000 - elapsed ~/ 10).clamp(0, 1000);
      final points = 100 + bonus;
      final currentScore = s.room.players.firstWhere((p) => p.uid == currentUid).score;
      await _mpRepo.updatePlayerScore(_currentRoomId!, currentUid, currentScore + points);
    }

    // Update answered flag immediately (don't wait for RTDB round-trip)
    emit(RoomPlaying(
      room: s.room,
      questions: s.questions,
      currentIndex: s.currentIndex,
      answered: true,
      timeLeft: s.timeLeft,
    ));
  }

  Future<void> _onAdvance(AdvanceToNextQuestion event, Emitter<RoomState> emit) async {
    if (_currentRoomId == null || state is! RoomPlaying) return;
    final s = state as RoomPlaying;
    if (s.currentIndex + 1 >= s.questions.length) {
      await _mpRepo.finishGame(_currentRoomId!);
    } else {
      await _mpRepo.advanceQuestion(_currentRoomId!, s.currentIndex + 1);
    }
  }

  Future<void> _onRoomUpdated(RoomUpdated event, Emitter<RoomState> emit) async {
    final room = event.room;

    if (room.status == RoomStatus.waiting) {
      emit(RoomWaiting(room));
    } else if (room.status == RoomStatus.playing) {
      // Block concurrent fetches — multiple RTDB events can fire simultaneously
      if (_questions.isEmpty && _loadingQuestions) return;

      // Fetch questions if not loaded yet
      if (_questions.isEmpty) {
        if (room.lessonId.isEmpty || room.subjectId.isEmpty) {
          emit(RoomError('Room has no lesson assigned.'));
          return;
        }
        _loadingQuestions = true;
        try {
          _questions = await _contentRepo.fetchQuestionsForLesson(
              room.lessonId, room.subjectId);
        } catch (e) {
          _loadingQuestions = false;
          emit(RoomError('Failed to load questions: $e'));
          return;
        }
        _loadingQuestions = false;
      }

      // Still empty after fetch — Firestore returned nothing
      if (_questions.isEmpty) {
        emit(RoomError('No questions found for this lesson.'));
        return;
      }

      final newIndex = room.currentQuestionIndex;
      final safeIndex = newIndex.clamp(0, _questions.length - 1);
      final prevState = state;

      if (safeIndex != _timerQuestionIndex) {
        _timerQuestionIndex = safeIndex;
        _questionStartTime = DateTime.now();
        trtartTimer(safeIndex);
      }

      final alreadyAnswered = prevState is RoomPlaying &&
          prevState.currentIndex == safeIndex &&
          prevState.answered;

      emit(RoomPlaying(
        room: room,
        questions: _questions,
        currentIndex: safeIndex,
        answered: alreadyAnswered,
        timeLeft: _timeLeft,
      ));
    } else if (room.status == RoomStatus.finished) {
      _timer?.cancel();
      emit(RoomFinished(room));
    }
  }

  void trtartTimer(int questionIndex) {
    _timer?.cancel();
    _timeLeft = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is! RoomPlaying) return;
      final s = state as RoomPlaying;
      if (s.currentIndex != questionIndex) { _timer?.cancel(); return; }
      _timeLeft = (_timeLeft - 1).clamp(0, 20);
      // Don't emit state here — UI has its own local timer for the countdown
      // Only act when time runs out
      if (_timeLeft == 0 && s.room.hostUid == currentUid) {
        add(AdvanceToNextQuestion());
      }
    });
  }

  void _listenRoom(String roomId) {
    _roomSub?.cancel();
    _roomSub = _mpRepo.watchRoom(roomId).listen((room) => add(RoomUpdated(room)));
  }

  Future<void> _onLeave(LeaveRoomRequested event, Emitter<RoomState> emit) async {
    _timer?.cancel();
    _roomSub?.cancel();
    if (_currentRoomId != null) {
      await _mpRepo.leaveRoom(_currentRoomId!, currentUid);
    }
    _currentRoomId = null;
    _questions = [];
    _timerQuestionIndex = -1;
    _loadingQuestions = false;
    emit(RoomInitial());
  }

  String? get currentRoomId => _currentRoomId;

  @override
  Future<void> close() {
    _timer?.cancel();
    _roomSub?.cancel();
    return super.close();
  }
}

// ─── Multiplayer Hub Screen ───────────────────────────────────────────────────

class MultiplayerHubScreen extends StatefulWidget {
  const MultiplayerHubScreen({super.key});
  @override
  State<MultiplayerHubScreen> createState() => _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends State<MultiplayerHubScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (ctx, lang) {
        final l10n = AppLocalizations(lang);
        return BlocListener<RoomBloc, RoomState>(
          listener: (ctx, state) {
            if (state is RoomWaiting) {
              context.push('/multiplayer/room');
            } else if (state is RoomError) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ));
            }
          },
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.play)),
            body: BlocBuilder<RoomBloc, RoomState>(
              builder: (ctx, state) {
                final loading = state is RoomLoading;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: NerpaMascot(size: 100, expression: 'happy')),
                      const SizedBox(height: AppDimens.paddingL),
                      Text(
                        l10n.tr(en: 'Play with friends!', ru: 'Играй с друзьями!', kz: 'Достарыңмен ойна!'),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: AppDimens.paddingXL),
                      NerpaButton(
                        label: l10n.createRoom,
                        icon: Icons.add_rounded,
                        loading: loading,
                        onPressed: loading ? null : () => trhowCreateRoomDialog(context, lang),
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      NerpaButton(
                        label: l10n.tr(en: 'Quick Match', ru: 'Быстрый матч', kz: 'Жылдам матч'),
                        icon: Icons.bolt_rounded,
                        outlined: true,
                        loading: loading,
                        onPressed: loading ? null : () => trhowQuickMatchDialog(context, lang),
                      ),
                      const SizedBox(height: AppDimens.paddingL),
                      const Divider(),
                      const SizedBox(height: AppDimens.paddingL),
                      Text(l10n.joinRoom, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeCtrl,
                              decoration: InputDecoration(hintText: l10n.roomCode),
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 6,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          SizedBox(
                            height: AppDimens.buttonHeight,
                            width: AppDimens.buttonHeight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimens.radiusM)),
                              ),
                              onPressed: loading || _codeCtrl.text.trim().isEmpty
                                  ? null
                                  : () => ctx.read<RoomBloc>().add(
                                      JoinRoomRequested(_codeCtrl.text.trim())),
                              child: const Icon(Icons.arrow_forward_rounded),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void trhowCreateRoomDialog(BuildContext context, AppLanguage lang) {
    showDialog(
      context: context,
      builder: (_) => _CreateRoomDialog(
        lang: lang,
        onConfirm: (subjectId, lessonId) => context
            .read<RoomBloc>()
            .add(CreateRoomRequested(subjectId: subjectId, lessonId: lessonId)),
      ),
    );
  }

  void trhowQuickMatchDialog(BuildContext context, AppLanguage lang) {
    showDialog(
      context: context,
      builder: (_) => _QuickMatchDialog(
        lang: lang,
        onConfirm: (subjectId) =>
            context.read<RoomBloc>().add(FindMatchRequested(subjectId)),
      ),
    );
  }
}

// ─── Create Room Dialog ───────────────────────────────────────────────────────

class _CreateRoomDialog extends StatefulWidget {
  final AppLanguage lang;
  final void Function(String subjectId, String lessonId) onConfirm;
  const _CreateRoomDialog({required this.lang, required this.onConfirm});
  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final _repo = ContentRepository();
  List<SubjectModel> trubjects = [];
  List<LessonModel> _lessons = [];
  SubjectModel? trelectedSubject;
  LessonModel? trelectedLesson;
  bool _loadingSubjects = true;
  bool _loadingLessons = false;

  @override
  void initState() { super.initState(); _loadSubjects(); }

  Future<void> _loadSubjects() async {
    try {
      final s = await _repo.fetchAllSubjects(langCode: widget.lang.code);
      if (mounted) setState(() { trubjects = s; _loadingSubjects = false; });
    } catch (_) { if (mounted) setState(() => _loadingSubjects = false); }
  }

  Future<void> trelectSubject(SubjectModel subject) async {
    setState(() { trelectedSubject = subject; trelectedLesson = null; _lessons = []; _loadingLessons = true; });
    try {
      final l = await _repo.fetchLessonsForSubject(subject.id, langCode: widget.lang.code);
      if (mounted) setState(() { _lessons = l; _loadingLessons = false; });
    } catch (_) { if (mounted) setState(() => _loadingLessons = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(widget.lang);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusXL)),
      title: Text(
        trelectedSubject == null
            ? l10n.tr(en: 'Choose a subject', ru: 'Выберите предмет', kz: 'Пән таңдаңыз')
            : l10n.tr(en: 'Choose a lesson', ru: 'Выберите урок', kz: 'Сабақ таңдаңыз'),
        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loadingSubjects
            ? const Center(child: CircularProgressIndicator(color: AppColors.skyBlue))
            : trelectedSubject == null ? _buildSubjectList() : _buildLessonList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (trelectedSubject != null) {
              setState(() { trelectedSubject = null; trelectedLesson = null; _lessons = []; });
            } else { Navigator.of(context).pop(); }
          },
          child: Text(
            trelectedSubject != null
                ? l10n.back
                : l10n.tr(en: 'Cancel', ru: 'Отмена', kz: 'Болдырмау'),
            style: const TextStyle(fontFamily: 'Nunito', color: AppColors.textSecondary),
          ),
        ),
        if (trelectedLesson != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusRound))),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirm(trelectedSubject!.id, trelectedLesson!.id);
            },
            child: Text(
              l10n.tr(en: 'Create', ru: 'Создать', kz: 'Жасау'),
              style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectList() {
    final l10n = AppLocalizations(widget.lang);
    if (trubjects.isEmpty) return Text(l10n.tr(en: 'No subjects found.', ru: 'Предметы не найдены.', kz: 'Пәндер жоқ.'),
        style: const TextStyle(fontFamily: 'Nunito'));
    return ListView.separated(
      shrinkWrap: true,
      itemCount: trubjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingS),
      itemBuilder: (_, i) {
        final s = trubjects[i];
        return ListTile(
          leading: Text(s.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(s.title, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.skyBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          onTap: () => trelectSubject(s),
        );
      },
    );
  }

  Widget _buildLessonList() {
    final l10n = AppLocalizations(widget.lang);
    if (_loadingLessons) return const Center(child: CircularProgressIndicator(color: AppColors.skyBlue));
    if (_lessons.isEmpty) return Text(l10n.noLessonsAvailable, style: const TextStyle(fontFamily: 'Nunito'));
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingS),
      itemBuilder: (_, i) {
        final l = _lessons[i];
        final sel = trelectedLesson?.id == l.id;
        return ListTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: sel ? AppColors.skyBlue : AppColors.skyBlueSurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Center(child: Text('${i + 1}', style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800,
                color: sel ? Colors.white : AppColors.skyBlue))),
          ),
          title: Text(l.title, style: TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w700,
              color: sel ? AppColors.skyBlue : AppColors.textPrimary)),
          trailing: sel ? const Icon(Icons.check_circle_rounded, color: AppColors.skyBlue) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            side: BorderSide(color: sel ? AppColors.skyBlue : AppColors.cardBorder, width: sel ? 2 : 1),
          ),
          onTap: () => setState(() => trelectedLesson = l),
        );
      },
    );
  }
}

// ─── Quick Match Dialog ───────────────────────────────────────────────────────

class _QuickMatchDialog extends StatefulWidget {
  final AppLanguage lang;
  final void Function(String subjectId) onConfirm;
  const _QuickMatchDialog({required this.lang, required this.onConfirm});
  @override
  State<_QuickMatchDialog> createState() => _QuickMatchDialogState();
}

class _QuickMatchDialogState extends State<_QuickMatchDialog> {
  final _repo = ContentRepository();
  List<SubjectModel> trubjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.fetchAllSubjects(langCode: widget.lang.code).then((s) {
      if (mounted) setState(() { trubjects = s; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(widget.lang);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusXL)),
      title: Text(
        l10n.tr(en: 'Quick Match', ru: 'Быстрый матч', kz: 'Жылдам матч'),
        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.skyBlue))
            : trubjects.isEmpty
                ? Text(l10n.tr(en: 'No subjects found.', ru: 'Предметы не найдены.', kz: 'Пәндер жоқ.'),
                    style: const TextStyle(fontFamily: 'Nunito'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: trubjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingS),
                    itemBuilder: (_, i) {
                      final s = trubjects[i];
                      return ListTile(
                        leading: Text(s.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(s.title, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.bolt_rounded, color: AppColors.skyBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        onTap: () { Navigator.of(context).pop(); widget.onConfirm(s.id); },
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.tr(en: 'Cancel', ru: 'Отмена', kz: 'Болдырмау'),
            style: const TextStyle(fontFamily: 'Nunito', color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ─── Waiting Room Screen ──────────────────────────────────────────────────────

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (ctx, lang) {
        final l10n = AppLocalizations(lang);
        return BlocConsumer<RoomBloc, RoomState>(
          listener: (ctx, state) {
            if (state is RoomPlaying) context.pushReplacement('/multiplayer/game');
            else if (state is RoomInitial) context.pop();
          },
          builder: (ctx, state) {
            if (state is! RoomWaiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)));
            }

            final room = state.room;
            final myUid = ctx.read<RoomBloc>().currentUid;
            final isHost = room.hostUid == myUid;
            final allReady = room.players.isNotEmpty && room.players.every((p) => p.isReady);
            final myPlayer = room.players.where((p) => p.uid == myUid).firstOrNull;
            final amReady = myPlayer?.isReady ?? false;
            final roomId = ctx.read<RoomBloc>().currentRoomId ?? room.id;

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.tr(en: 'Waiting Room', ru: 'Зал ожидания', kz: 'Күту бөлмесі')),
                leading: BackButton(onPressed: () => ctx.read<RoomBloc>().add(LeaveRoomRequested())),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    tooltip: l10n.tr(en: 'Room Chat', ru: 'Чат комнаты', kz: 'Бөлме чаты'),
                    onPressed: () => context.push('/multiplayer/chat/$roomId'),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlueSurface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tag, size: 16, color: AppColors.skyBlue),
                            const SizedBox(width: 4),
                            Text(room.id, style: const TextStyle(
                              fontFamily: 'Nunito', fontWeight: FontWeight.w800,
                              color: AppColors.skyBlue, letterSpacing: 2,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.players} (${room.players.length}/4)',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      l10n.tr(en: 'Share the room code with friends!', ru: 'Поделитесь кодом комнаты!', kz: 'Бөлме кодын достарыңызбен бөлісіңіз!'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    Expanded(
                      child: ListView.separated(
                        itemCount: room.players.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingM),
                        itemBuilder: (_, i) {
                          final p = room.players[i];
                          return Container(
                            padding: const EdgeInsets.all(AppDimens.paddingM),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppDimens.radiusL),
                              border: Border.all(
                                color: p.isReady ? AppColors.answerCorrect : AppColors.cardBorder,
                                width: p.isReady ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.skyBlueSurface,
                                  child: Text(
                                    p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.skyBlue),
                                  ),
                                ),
                                const SizedBox(width: AppDimens.paddingM),
                                Expanded(child: Text(p.displayName, style: Theme.of(context).textTheme.titleLarge)),
                                if (p.uid == room.hostUid)
                                  Chip(
                                    label: Text(
                                      l10n.tr(en: 'Host', ru: 'Хост', kz: 'Хост'),
                                      style: const TextStyle(fontFamily: 'Nunito'),
                                    ),
                                    backgroundColor: AppColors.skyBlueSurface,
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  p.isReady ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: p.isReady ? AppColors.answerCorrect : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    NerpaButton(
                      label: amReady
                          ? l10n.tr(en: 'Not Ready', ru: 'Не готов', kz: 'Дайын емес')
                          : l10n.ready,
                      outlined: !amReady,
                      onPressed: () => ctx.read<RoomBloc>().add(SetReadyRequested(!amReady)),
                    ),
                    if (isHost) ...[
                      const SizedBox(height: AppDimens.paddingM),
                      NerpaButton(
                        label: allReady
                            ? l10n.startGame
                            : l10n.tr(en: 'Waiting for players...', ru: 'Ожидание игроков...', kz: 'Ойыншылар күтілуде...'),
                        onPressed: allReady
                            ? () => ctx.read<RoomBloc>().add(StartGameRequested())
                            : null,
                      ),
                    ],
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

// ─── Game Screen ──────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (ctx, lang) {
        final l10n = AppLocalizations(lang);
        return BlocConsumer<RoomBloc, RoomState>(
          listener: (ctx, state) {
            if (state is RoomFinished) context.pushReplacement('/multiplayer/results');
            if (state is RoomError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ));
              context.go('/home');
            }
            if (state is RoomPlaying && !state.answered) _inputCtrl.clear();
          },
          buildWhen: (prev, curr) {
            if (curr is! RoomPlaying) return true;
            if (prev is! RoomPlaying) return true;
            return prev.currentIndex != curr.currentIndex ||
                prev.answered != curr.answered ||
                prev.questions.length != curr.questions.length;
          },
          builder: (ctx, state) {
            if (state is! RoomPlaying ||
                state.questions.isEmpty ||
                state.currentIndex >= state.questions.length) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)));
            }

            final q = state.questions[state.currentIndex];
            final isHost = state.room.hostUid == ctx.read<RoomBloc>().currentUid;
            final isFreeInput = q.type == QuestionType.freeInput;

            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: QuizProgressBar(current: state.currentIndex + 1, total: state.questions.length),
                actions: [
                  _TimerBadge(questionIndex: state.currentIndex),
                  const SizedBox(width: 12),
                ],
              ),
              body: Column(
                children: [
                  BlocBuilder<RoomBloc, RoomState>(
                    buildWhen: (prev, curr) =>
                        prev is RoomPlaying && curr is RoomPlaying && prev.room.players != curr.room.players,
                    builder: (_, s) {
                      final players = s is RoomPlaying
                          ? ([...s.room.players]..sort((a, b) => b.score.compareTo(a.score)))
                          : <RoomPlayer>[];
                      return SizedBox(
                        height: 56,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingL, vertical: AppDimens.paddingS),
                          children: players.map((p) => Padding(
                                padding: const EdgeInsets.only(right: AppDimens.paddingS),
                                child: Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: AppColors.skyBlue,
                                    child: Text(
                                      p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                  ),
                                  label: Text('${p.displayName} · ${p.score}',
                                      style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              )).toList(),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.paddingL),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppDimens.paddingL),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(q.questionText,
                                style: Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: AppDimens.paddingL),

                          if (!state.answered) ...[
                            if (isFreeInput) ...[
                              TextField(
                                controller: _inputCtrl,
                                autofocus: false,
                                decoration: InputDecoration(
                                  hintText: l10n.yourAnswer,
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.send_rounded, color: AppColors.skyBlue),
                                    onPressed: () {
                                      final ans = _inputCtrl.text.trim();
                                      if (ans.isEmpty) return;
                                      ctx.read<RoomBloc>().add(AnswerGameQuestion(answer: ans, answeredAt: DateTime.now()));
                                    },
                                  ),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (ans) {
                                  if (ans.trim().isEmpty) return;
                                  ctx.read<RoomBloc>().add(AnswerGameQuestion(answer: ans.trim(), answeredAt: DateTime.now()));
                                },
                              ),
                            ] else ...[
                              ...q.options.map((opt) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                    child: NerpaButton(
                                      label: opt,
                                      onPressed: () => ctx.read<RoomBloc>().add(
                                          AnswerGameQuestion(answer: opt, answeredAt: DateTime.now())),
                                    ),
                                  )),
                            ],
                          ] else ...[
                            const Icon(Icons.check_circle_rounded, color: AppColors.answerCorrect, size: 64),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tr(en: 'Answer submitted! Waiting for others...', ru: 'Ответ отправлен! Ждём остальных...', kz: 'Жауап жіберілді! Басқаларды күтуде...'),
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            if (isHost) ...[
                              const SizedBox(height: AppDimens.paddingL),
                              NerpaButton(
                                label: l10n.tr(en: 'Next Question →', ru: 'Следующий вопрос →', kz: 'Келесі сұрақ →'),
                                onPressed: () => ctx.read<RoomBloc>().add(AdvanceToNextQuestion()),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TimerBadge extends StatefulWidget {
  final int questionIndex;
  const _TimerBadge({required this.questionIndex});

  @override
  State<_TimerBadge> createState() => _TimerBadgeState();
}

class _TimerBadgeState extends State<_TimerBadge> {
  late int treconds;
  Timer? _timer;

  @override
  void initState() { super.initState(); _reset(); }

  @override
  void didUpdateWidget(_TimerBadge old) {
    super.didUpdateWidget(old);
    if (old.questionIndex != widget.questionIndex) _reset();
  }

  void _reset() {
    _timer?.cancel();
    treconds = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { treconds = (treconds - 1).clamp(0, 20); });
      if (treconds == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = treconds <= 5 ? AppColors.error : AppColors.skyBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
      ),
      child: Text('$treconds', style: TextStyle(
        fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 18, color: color,
      )),
    );
  }
}

// ─── Game Results Screen ──────────────────────────────────────────────────────

class GameResultsScreen extends StatelessWidget {
  const GameResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (ctx, lang) {
        final l10n = AppLocalizations(lang);
        return BlocBuilder<RoomBloc, RoomState>(
          builder: (ctx, state) {
            if (state is! RoomFinished) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)));
            }

            final sorted = [...state.room.players]..sort((a, b) => b.score.compareTo(a.score));
            final roomId = state.room.id;

            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                child: Column(
                  children: [
                    const NerpaMascot(size: 100, expression: 'happy'),
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      '🏆 ${l10n.tr(en: 'Final Results', ru: 'Итоги', kz: 'Қорытынды')}',
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (_, i) {
                          final p = sorted[i];
                          const medals = ['🥇', '🥈', '🥉'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                            padding: const EdgeInsets.all(AppDimens.paddingM),
                            decoration: BoxDecoration(
                              color: i == 0 ? const Color(0xFFFFF9C4) : AppColors.white,
                              borderRadius: BorderRadius.circular(AppDimens.radiusL),
                              border: Border.all(color: i == 0 ? AppColors.warning : AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Text(i < 3 ? medals[i] : '${i + 1}.', style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: AppDimens.paddingM),
                                Expanded(child: Text(p.displayName, style: Theme.of(context).textTheme.titleLarge)),
                                Text(
                                  '${p.score} ${l10n.tr(en: 'pts', ru: 'оч.', kz: 'ұпай')}',
                                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.skyBlue),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    NerpaButton(
                      label: l10n.tr(en: 'Post-game Chat', ru: 'Чат после игры', kz: 'Ойыннан кейінгі чат'),
                      icon: Icons.chat_bubble_outline_rounded,
                      outlined: true,
                      onPressed: () => context.push('/multiplayer/chat/$roomId'),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    NerpaButton(
                      label: l10n.tr(en: 'Back to Home', ru: 'На главную', kz: 'Басты бетке'),
                      onPressed: () {
                        ctx.read<RoomBloc>().add(LeaveRoomRequested());
                        context.go('/home');
                      },
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
