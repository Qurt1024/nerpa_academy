import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';

// ─── App Icon Widget ─────────────────────────────────────────────────────────

class AppIcon extends StatelessWidget {
  final double size;
  const AppIcon({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/appIcon.svg',
      width: size,
      height: size,
    );
  }
}

// ─── Nerpa Mascot Widget ─────────────────────────────────────────────────────

class NerpaMascot extends StatefulWidget {
  final double size;
  final String expression; // 'happy', 'sad', 'default'

  const NerpaMascot({
    super.key,
    this.size = 120,
    this.expression = 'default',
  });

  @override
  State<NerpaMascot> createState() => _NerpaMascotState();
}

class _NerpaMascotState extends State<NerpaMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _assetPath {
    switch (widget.expression) {
      case 'happy':
        return 'assets/images/nerpHappy.svg';
      case 'sad':
        return 'assets/images/nerpSad.svg';
      default:
        return 'assets/images/nerpNeutral.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -_bounce.value),
        child: child,
      ),
      child: SvgPicture.asset(
        _assetPath,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}

// ─── Fish Bar (replaces HeartBar) ────────────────────────────────────────────

class HeartBar extends StatelessWidget {
  final int hearts;
  final int maxHearts;

  const HeartBar({
    super.key,
    required this.hearts,
    this.maxHearts = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxHearts, (i) {
        final alive = i < hearts;
        return AnimatedSwitcher(
          duration: AppDimens.animNormal,
          child: Padding(
            key: ValueKey('$i-$alive'),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SvgPicture.asset(
              alive
                  ? 'assets/images/fihAlive.svg'
                  : 'assets/images/fihDead.svg',
              width: 28,
              height: 28,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Primary Button ──────────────────────────────────────────────────────────

class NerpaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;
  final IconData? icon;

  const NerpaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: onPressed, child: child);
    }
    return ElevatedButton(onPressed: onPressed, child: child);
  }
}

// ─── Subject Card ────────────────────────────────────────────────────────────

class SubjectCard extends StatelessWidget {
  final String emoji;
  final String title;
  final int lessonCount;
  final bool selected;
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.lessonCount,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animNormal,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.skyBlue : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          border: Border.all(
            color: selected ? AppColors.skyBlue : AppColors.cardBorder,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (lessonCount > 0)
                    Text(
                      '$lessonCount уроков',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: selected
                            ? AppColors.white.withOpacity(0.85)
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Bar ────────────────────────────────────────────────────────────

class QuizProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: AppColors.skyBlueLight,
        valueColor:
            const AlwaysStoppedAnimation<Color>(AppColors.skyBlue),
      ),
    );
  }
}

// ─── Loading Overlay ─────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black26,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.skyBlue),
      ),
    );
  }
}
