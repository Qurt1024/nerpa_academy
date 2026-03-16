import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nerpa_academy/core/l10n/app_localizations.dart';
import 'package:nerpa_academy/core/l10n/language_cubit.dart';
import 'package:nerpa_academy/data/repositories/multiplayer_repository.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/content_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/lessons/bloc/lesson_bloc.dart';
import 'features/multiplayer/multiplayer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'nerpa-academy',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load persisted language before app launches
  final languageCubit = LanguageCubit();
  await languageCubit.loadSavedLanguage();

  runApp(NerpaAcademyApp(languageCubit: languageCubit));
}

class NerpaAcademyApp extends StatefulWidget {
  final LanguageCubit languageCubit;
  const NerpaAcademyApp({super.key, required this.languageCubit});

  @override
  State<NerpaAcademyApp> createState() => _NerpaAcademyAppState();
}

class _NerpaAcademyAppState extends State<NerpaAcademyApp> {
  final _authRepo = AuthRepository();
  final _contentRepo = ContentRepository();
  final _multiplayerRepo = MultiplayerRepository();

  late final AuthBloc _authBloc;
  late final LessonBloc _lessonBloc;
  late final _RouterNotifier _routerNotifier;
  late final router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(_authRepo)..add(AuthCheckRequested());
    _lessonBloc = LessonBloc(_contentRepo);
    _routerNotifier = _RouterNotifier(_authBloc);
    router = AppRouter.router(_authBloc, _routerNotifier);
  }

  @override
  void dispose() {
    _authBloc.close();
    _lessonBloc.close();
    _routerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Language cubit must be outermost so l10n works everywhere
        BlocProvider.value(value: widget.languageCubit),
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _lessonBloc),
        BlocProvider<RoomBloc>(
          create: (_) {
            final user = _authRepo.currentUser;
            return RoomBloc(
              mpRepo: _multiplayerRepo,
              contentRepo: _contentRepo,
              currentUid: user?.uid ?? '',
              displayName: user?.displayName ?? user?.email ?? 'Player',
            );
          },
        ),
      ],
      child: BlocBuilder<LanguageCubit, AppLanguage>(
        // Rebuild MaterialApp when language changes so the whole tree gets new l10n
        builder: (ctx, lang) {
          return MaterialApp.router(
            title: 'Nerpa Academy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: SafeArea(top: false, child: child!),
              );
            },
          );
        },
      ),
    );
  }
}

// Only notifies router on real login/logout transitions
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(AuthBloc authBloc) {
    authBloc.stream.listen((state) {
      if (state is AuthAuthenticated ||
          state is AuthUnauthenticated ||
          state is AuthNeedsSubjectSelection) {
        notifyListeners();
      }
    });
  }
}
