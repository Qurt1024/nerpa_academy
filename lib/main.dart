import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/multiplayer_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/lessons/bloc/lesson_bloc.dart';
import 'features/multiplayer/multiplayer.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(name:'nerpa-academy',options: DefaultFirebaseOptions.currentPlatform);
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const NerpaAcademyApp());
}

class NerpaAcademyApp extends StatefulWidget {
  const NerpaAcademyApp({super.key});

  @override
  State<NerpaAcademyApp> createState() => _NerpaAcademyAppState();
}

class _NerpaAcademyAppState extends State<NerpaAcademyApp> {
  final _authRepo = AuthRepository();
  final _contentRepo = ContentRepository();
  final _multiplayerRepo = MultiplayerRepository();

  late final AuthBloc _authBloc;
  late final LessonBloc _lessonBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(_authRepo)..add(AuthCheckRequested());
    _lessonBloc = LessonBloc(_contentRepo);
  }

  @override
  void dispose() {
    _authBloc.close();
    _lessonBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _lessonBloc),
        // RoomBloc created lazily with user info after auth
        BlocProvider<RoomBloc>(
          create: (_) {
            final user = _authRepo.currentUser;
            return RoomBloc(
              mpRepo: _multiplayerRepo,
              contentRepo: _contentRepo,
              currentUid: user?.uid ?? '',
              displayName: user?.displayName ?? user?.email ?? 'Игрок',
            );
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: _authBloc,
        builder: (context, _) {
          final router = AppRouter.router(context);
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
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
