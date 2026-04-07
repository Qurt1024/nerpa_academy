import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nerpa_academy/core/l10n/app_localizations.dart';
import 'package:nerpa_academy/core/l10n/language_cubit.dart';
import 'package:nerpa_academy/data/repositories/auth_repository.dart';
import 'package:nerpa_academy/data/repositories/content_repository.dart';
import 'package:nerpa_academy/data/repositories/multiplayer_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../auth/bloc/auth_bloc.dart';

// ─── Chat Screen ──────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final ChatRepository _chatRepo;

  @override
  void initState() {
    super.initState();
    _chatRepo = ChatRepository();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(String uid, String name) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await _chatRepo.sendMessage(
        roomId: widget.roomId,
        senderUid: uid,
        senderName: name,
        text: text,
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: AppDimens.animNormal,
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('flagged')
                  ? context.l10n.tr(en: '⚠️ Message blocked by moderation.', ru: '⚠️ Сообщение заблокировано модерацией.', kz: '⚠️ Хабарлама модерациямен бұғатталды.')
                  : context.l10n.tr(en: 'Failed to send message.', ru: 'Не удалось отправить сообщение.', kz: 'Хабарламаны жіберу мүмкін болмады.'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (_, __) => BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        final l10n = context.l10n;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tr(en: 'Room Chat', ru: 'Чат комнаты', kz: 'Бөлме чаты')),
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatRepo.watchMessages(widget.roomId),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.skyBlue),
                      );
                    }

                    final messages = snap.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.tr(
                            en: 'No messages yet.\nSay hi! 👋',
                            ru: 'Сообщений пока нет.\nПоздоровайся! 👋',
                            kz: 'Хабарламалар жоқ.\nСәлем де! 👋',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMe = msg.senderUid == user?.uid;
                        return _MessageBubble(message: msg, isMe: isMe);
                      },
                    );
                  },
                ),
              ),
              _ChatInput(
                controller: _msgCtrl,
                onSend: user != null
                    ? () => _send(user.uid, user.displayName ?? user.email)
                    : null,
              ),
            ],
          ),
        );
      },
    ), // end BlocBuilder<AuthBloc>
    ); // end BlocBuilder<LanguageCubit>
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS + 2,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.skyBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimens.radiusL),
            topRight: const Radius.circular(AppDimens.radiusL),
            bottomLeft: Radius.circular(isMe ? AppDimens.radiusL : AppDimens.paddingXS),
            bottomRight: Radius.circular(isMe ? AppDimens.paddingXS : AppDimens.radiusL),
          ),
          border: isMe ? null : Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.skyBlue,
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isMe ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;

  const _ChatInput({required this.controller, this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.paddingM,
        AppDimens.paddingS,
        AppDimens.paddingM,
        AppDimens.paddingM + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 140,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                counterText: '',
              ),
              onSubmitted: (_) => onSend?.call(),
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
              onPressed: onSend,
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXL)),
        title: Text(l10n.deleteAccountConfirmTitle,
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: Text(l10n.deleteAccountConfirmBody,
            style: const TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: Text(l10n.tr(en: 'Cancel', ru: 'Отмена', kz: 'Болдырмау'),
                style: const TextStyle(
                    fontFamily: 'Nunito', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: Text(l10n.deleteAccount,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppColors.error,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthDeleteAccountRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (_, __) {
        // Re-read l10n inside the BlocBuilder so every language change
        // triggers a full rebuild of all profile-screen labels.
        final l10n = context.l10n;
        return BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthUnauthenticated) {
              context.go('/');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.deleteAccountError),
                backgroundColor: AppColors.error,
              ));
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, state) {
              final user = state is AuthAuthenticated ? state.user : null;
              final isLoading = state is AuthLoading;

          return Scaffold(
            appBar: AppBar(title: Text(l10n.profile)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingL),
              child: Column(
                children: [
                  const SizedBox(height: AppDimens.paddingM),
                  const NerpaMascot(size: 100),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(
                    user?.displayName ?? user?.email ?? 'Player',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (user?.email != null) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: AppDimens.paddingXL),

                  // ── Stats tiles ──────────────────────────────────────────────
                  _ProfileTile(
                    icon: Icons.star_rounded,
                    label: l10n.totalScore,
                    value: '${user?.totalScore ?? 0}',
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  _ProfileTile(
                    icon: Icons.menu_book_rounded,
                    label: l10n.subjectsSelected,
                    value: '${user?.selectedSubjectIds.length ?? 0}',
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  _ProfileTile(
                    icon: Icons.check_circle_rounded,
                    label: l10n.completedLessonsLabel,
                    value: '${user?.completedLessons.length ?? 0}',
                  ),
                  const SizedBox(height: AppDimens.paddingXL),

                  // ── Language picker ──────────────────────────────────────────
                  _LanguagePicker(),
                  const SizedBox(height: AppDimens.paddingM),

                  // ── Edit subjects ────────────────────────────────────────────
                  if (user != null)
                    NerpaButton(
                      label: l10n.editSubjects,
                      icon: Icons.menu_book_rounded,
                      outlined: true,
                      onPressed: isLoading
                          ? null
                          : () => _showEditSubjectsSheet(context, user),
                    ),
                  const SizedBox(height: AppDimens.paddingM),

                  // ── Sign out ─────────────────────────────────────────────────
                  NerpaButton(
                    label: l10n.signOut,
                    outlined: true,
                    icon: Icons.logout_rounded,
                    onPressed: isLoading
                        ? null
                        : () {
                            ctx.read<AuthBloc>().add(AuthSignOutRequested());
                            context.go('/');
                          },
                  ),
                  const SizedBox(height: AppDimens.paddingM),

                  // ── Delete account ───────────────────────────────────────────
                  if (user != null)
                    Theme(
                      data: Theme.of(context).copyWith(
                        outlinedButtonTheme: OutlinedButtonThemeData(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      child: NerpaButton(
                        label: l10n.deleteAccount,
                        icon: Icons.delete_forever_rounded,
                        outlined: true,
                        loading: isLoading,
                        onPressed: isLoading ? null : () => _confirmDelete(context),
                      ),
                    ),
                  const SizedBox(height: AppDimens.paddingXL),
                ],
              ),
            ),
          );
        },
      ),
    );
    },
  );
  }
}

void _showEditSubjectsSheet(BuildContext context, UserModel user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: _EditSubjectsSheet(user: user),
    ),
  );
}

// ─── Edit Subjects Bottom Sheet ───────────────────────────────────────────────

class _EditSubjectsSheet extends StatefulWidget {
  final UserModel user;
  const _EditSubjectsSheet({required this.user});

  @override
  State<_EditSubjectsSheet> createState() => _EditSubjectsSheetState();
}

class _EditSubjectsSheetState extends State<_EditSubjectsSheet> {
  final _repo = ContentRepository();
  List<SubjectModel> _subjects = [];
  late Set<String> _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.user.selectedSubjectIds);
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final all = await _repo.fetchAllSubjects();
      if (mounted) setState(() { _subjects = all; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _toggle(String id) => setState(() {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
  });

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectSubject)),
      );
      return;
    }
    setState(() => _saving = true);
    context.read<AuthBloc>().add(AuthSubjectsUpdateRequested(
      uid: widget.user.uid,
      subjectIds: _selected.toList(),
    ));
    // Wait for the bloc to finish then close the sheet
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final langCode = context.read<LanguageCubit>().state.code;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXL)),
        ),
        child: Column(
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            const SizedBox(height: AppDimens.paddingS),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingL, AppDimens.paddingM,
                  AppDimens.paddingL, AppDimens.paddingS),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.editSubjects,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Subject list ──────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.skyBlue))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: AppDimens.paddingM),
                              Text(l10n.couldNotLoadSubjects,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: AppDimens.paddingM),
                              NerpaButton(label: l10n.retry, onPressed: _loadSubjects),
                            ],
                          ),
                        )
                      : ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(AppDimens.paddingL),
                          children: [
                            // Regular subjects
                            ..._subjects
                                .where((s) => !s.id.startsWith('language_'))
                                .map((s) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                      child: SubjectCard(
                                        emoji: s.emoji,
                                        title: s.localTitle(langCode),
                                        lessonCount: s.lessonCount,
                                        selected: _selected.contains(s.id),
                                        onTap: () => _toggle(s.id),
                                      ),
                                    )),
                            // Language subjects section
                            const SizedBox(height: AppDimens.paddingS),
                            Text(l10n.chooseLanguageSubject,
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: AppDimens.paddingM),
                            ..._subjects
                                .where((s) => s.id.startsWith('language_'))
                                .map((s) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                      child: SubjectCard(
                                        emoji: s.emoji,
                                        title: s.localTitle(langCode),
                                        lessonCount: s.lessonCount,
                                        selected: _selected.contains(s.id),
                                        onTap: () => _toggle(s.id),
                                      ),
                                    )),
                            const SizedBox(height: AppDimens.paddingXL),
                          ],
                        ),
            ),
            // ── Save button ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.paddingL,
                AppDimens.paddingM,
                AppDimens.paddingL,
                AppDimens.paddingL +
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: NerpaButton(
                label: l10n.continueText,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Language Picker ──────────────────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (ctx, currentLang) {
        return Container(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.skyBlueSurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                    child: const Icon(Icons.language_rounded, color: AppColors.skyBlue),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Text(l10n.appLanguageLabel, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: AppLanguage.values.map((lang) {
                  final selected = lang == currentLang;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () async {
                          await ctx.read<LanguageCubit>().changeLanguage(lang);
                          final authState = ctx.read<AuthBloc>().state;
                          if (authState is AuthAuthenticated) {
                            await AuthRepository().updateAppLanguage(
                              authState.user.uid,
                              lang.code,
                            );
                          }
                        },
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
                              fontSize: 12,
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
          ),
        );
      },
    );
  }
}

// ─── Profile Tile ─────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
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
            child: Icon(icon, color: AppColors.skyBlue),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.skyBlue,
            ),
          ),
        ],
      ),
    );
  }
}
