import 'package:flutter/material.dart';
import 'package:nerpa_academy/core/constants/app_constants.dart';


// ─── Nerpa Mascot Widget ─────────────────────────────────────────────────────

class NerpaMascot extends StatefulWidget {
  final double size;
  final String expression; // 'happy', 'sad', 'think', 'default'

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -_bounce.value),
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _NerpaPainter(expression: widget.expression),
        ),
      ),
    );
  }
}

class _NerpaPainter extends CustomPainter {
  final String expression;
  _NerpaPainter({required this.expression});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = const Color(0xFF607D8B);
    final bellyPaint = Paint()..color = const Color(0xFFB0BEC5);
    final eyePaint = Paint()..color = Colors.black;
    final whitePaint = Paint()..color = Colors.white;
    final nosePaint = Paint()..color = const Color(0xFF37474F);

    // Body
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.55),
          width: w * 0.82,
          height: h * 0.72),
      bodyPaint,
    );

    // Belly
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.62),
          width: w * 0.52,
          height: h * 0.46),
      bellyPaint,
    );

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.3), w * 0.3, bodyPaint);

    // Eyes white
    canvas.drawCircle(Offset(w * 0.37, h * 0.27), w * 0.085, whitePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.27), w * 0.085, whitePaint);

    // Eyes pupil
    if (expression == 'sad') {
      canvas.drawCircle(
          Offset(w * 0.37, h * 0.29), w * 0.045, eyePaint);
      canvas.drawCircle(
          Offset(w * 0.63, h * 0.29), w * 0.045, eyePaint);
    } else {
      canvas.drawCircle(
          Offset(w * 0.37, h * 0.27), w * 0.045, eyePaint);
      canvas.drawCircle(
          Offset(w * 0.63, h * 0.27), w * 0.045, eyePaint);
    }

    // Nose
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.33),
          width: w * 0.12,
          height: w * 0.07),
      nosePaint,
    );

    // Whiskers
    final whiskerPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // Left whiskers
    canvas.drawLine(
        Offset(w * 0.1, h * 0.31), Offset(w * 0.38, h * 0.33), whiskerPaint);
    canvas.drawLine(
        Offset(w * 0.1, h * 0.36), Offset(w * 0.38, h * 0.35), whiskerPaint);
    // Right whiskers
    canvas.drawLine(
        Offset(w * 0.9, h * 0.31), Offset(w * 0.62, h * 0.33), whiskerPaint);
    canvas.drawLine(
        Offset(w * 0.9, h * 0.36), Offset(w * 0.62, h * 0.35), whiskerPaint);

    // Mouth / expression
    final mouthPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (expression == 'happy') {
      final path = Path()
        ..moveTo(w * 0.42, h * 0.37)
        ..quadraticBezierTo(w * 0.5, h * 0.42, w * 0.58, h * 0.37);
      canvas.drawPath(path, mouthPaint);
    } else if (expression == 'sad') {
      final path = Path()
        ..moveTo(w * 0.42, h * 0.39)
        ..quadraticBezierTo(w * 0.5, h * 0.35, w * 0.58, h * 0.39);
      canvas.drawPath(path, mouthPaint);
    } else {
      canvas.drawLine(
          Offset(w * 0.43, h * 0.38), Offset(w * 0.57, h * 0.38), mouthPaint);
    }

    // Flippers
    final flipperPaint = Paint()..color = const Color(0xFF546E7A);
    // Left
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.1, h * 0.6),
          width: w * 0.22,
          height: w * 0.12),
      flipperPaint,
    );
    // Right
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.9, h * 0.6),
          width: w * 0.22,
          height: w * 0.12),
      flipperPaint,
    );

    // Tail
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.94),
          width: w * 0.3,
          height: w * 0.14),
      flipperPaint,
    );
  }

  @override
  bool shouldRepaint(_NerpaPainter old) => old.expression != expression;
}

// ─── Heart Bar ──────────────────────────────────────────────────────────────

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
        final filled = i < hearts;
        return AnimatedSwitcher(
          duration: AppDimens.animNormal,
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            key: ValueKey('$i-$filled'),
            color: filled ? AppColors.heartFull : AppColors.heartEmpty,
            size: 28,
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
