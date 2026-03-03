import 'package:flutter/material.dart';

/// Основная кнопка приложения.
///
/// Принимает `label` (или `text` для обратной совместимости).
/// Все варианты поддерживают [isLoading].
class AppButton extends StatelessWidget {
  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final _AppButtonVariant _variant;

  String get _effectiveLabel => label ?? text ?? '';

  const AppButton.primary({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.text_btn({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _AppButtonVariant.danger;

  /// Default constructor → primary style.
  /// Accepts both `text:` and `label:` for flexibility.
  const AppButton({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _AppButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget loadingIndicator(Color color) => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        );

    switch (_variant) {
      case _AppButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            child: isLoading
                ? loadingIndicator(colorScheme.onPrimary)
                : Text(_effectiveLabel),
          ),
        );

      case _AppButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            child: isLoading
                ? loadingIndicator(colorScheme.primary)
                : Text(_effectiveLabel),
          ),
        );

      case _AppButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          child: isLoading
              ? loadingIndicator(colorScheme.primary)
              : Text(_effectiveLabel),
        );

      case _AppButtonVariant.danger:
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: isLoading
                ? loadingIndicator(colorScheme.onError)
                : Text(_effectiveLabel),
          ),
        );
    }
  }
}

enum _AppButtonVariant { primary, secondary, text, danger }
