import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/auth_screens.dart';
import '../../features/home/screens/home_screens.dart';
import '../../features/lessons/screens/quiz_screens.dart';
import '../../features/multiplayer/multiplayer.dart';
import '../../features/chat/chat_profile_screens.dart';

class AppRouter {
  static GoRouter router(AuthBloc authBloc, Listenable refreshListenable) => GoRouter(
        initialLocation: '/',
        refreshListenable: refreshListenable,
        redirect: (ctx, state) {
          final authState = authBloc.state;
          final isAuth = authState is AuthAuthenticated;
          final isAuthRoute =
              state.matchedLocation.startsWith('/login') ||
                  state.matchedLocation.startsWith('/signup') ||
                  state.matchedLocation == '/';

          if (!isAuth && !isAuthRoute) return '/';
          if (isAuth && isAuthRoute) return '/home';
          return null;
        },
        routes: [
          // ── Auth ──────────────────────────────────────────────────────────
          GoRoute(
            path: '/',
            builder: (_, __) => const WelcomeScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: '/signup/step1',
            builder: (_, __) => const SignUpStep1Screen(),
          ),
          GoRoute(
            path: '/signup/step2',
            builder: (_, state) {
              final extra = state.extra as Map<String, String>;
              return SignUpStep2Screen(
                email: extra['email']!,
                password: extra['password']!,
              );
            },
          ),

          // ── Shell (Bottom Nav) ─────────────────────────────────────────────
          ShellRoute(
            builder: (_, __, child) => MainShell(child: child),
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
              GoRoute(
                path: '/multiplayer',
                builder: (_, __) => const MultiplayerHubScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),

          // ── Lessons ───────────────────────────────────────────────────────
          GoRoute(
            path: '/lessons/:subjectId',
            builder: (_, state) => LessonsScreen(
              subjectId: state.pathParameters['subjectId']!,
            ),
          ),
          GoRoute(
            path: '/lesson/:subjectId/:lessonId',
            builder: (_, state) => QuizScreenWidget(
              subjectId: state.pathParameters['subjectId']!,
            ),
          ),
          GoRoute(
            path: '/results/:subjectId',
            builder: (_, state) => ResultsScreen(
              subjectId: state.pathParameters['subjectId']!,
            ),
          ),

          // ── Multiplayer ───────────────────────────────────────────────────
          GoRoute(
            path: '/multiplayer/room',
            builder: (_, __) => const WaitingRoomScreen(),
          ),
          GoRoute(
            path: '/multiplayer/game',
            builder: (_, __) => const GameScreen(),
          ),
          GoRoute(
            path: '/multiplayer/results',
            builder: (_, __) => const GameResultsScreen(),
          ),
          GoRoute(
            path: '/chat/:roomId',
            builder: (_, state) => ChatScreen(
              roomId: state.pathParameters['roomId']!,
            ),
          ),
        ],
        errorBuilder: (_, state) => Scaffold(
          body: Center(
            child: Text('Page not found: ${state.uri}'),
          ),
        ),
      );
}
