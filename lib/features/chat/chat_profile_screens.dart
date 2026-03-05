import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../data/repositories/multiplayer_repository.dart';
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

  void _send(String uid, String name) {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _chatRepo.sendMessage(
      roomId: widget.roomId,
      senderUid: uid,
      senderName: name,
      text: text,
    );
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: AppDimens.animNormal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, authState) {
        final user =
            authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Room Chat'),
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatRepo.watchMessages(widget.roomId),
                  builder: (_, snap) {
                    if (snap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.skyBlue),
                      );
                    }

                    final messages = snap.data ?? [];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nSay hi! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                        return _MessageBubble(
                            message: msg, isMe: isMe);
                      },
                    );
                  },
                ),
              ),
              _ChatInput(
                controller: _msgCtrl,
                onSend: user != null
                    ? () => _send(
                          user.uid,
                          user.displayName ?? user.email,
                        )
                    : null,
              ),
            ],
          ),
        );
      },
    );
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
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS + 2,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.skyBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimens.radiusL),
            topRight: const Radius.circular(AppDimens.radiusL),
            bottomLeft: Radius.circular(
                isMe ? AppDimens.radiusL : AppDimens.paddingXS),
            bottomRight: Radius.circular(
                isMe ? AppDimens.paddingXS : AppDimens.radiusL),
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
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
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
                color:
                    isMe ? AppColors.white : AppColors.textPrimary,
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
        AppDimens.paddingM +
            MediaQuery.of(context).viewInsets.bottom,
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
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: AppStrings.typeMessage,
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
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusM),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Padding(
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
                  Text(
                    user!.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppDimens.paddingXL),
                _ProfileTile(
                  icon: Icons.star_rounded,
                  label: 'Total Score',
                  value: '${user?.totalScore ?? 0}',
                ),
                const SizedBox(height: AppDimens.paddingM),
                _ProfileTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Subjects Selected',
                  value: '${user?.selectedSubjectIds.length ?? 0}',
                ),
                const Spacer(),
                NerpaButton(
                  label: 'Sign Out',
                  outlined: true,
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    ctx.read<AuthBloc>().add(AuthSignOutRequested());
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
