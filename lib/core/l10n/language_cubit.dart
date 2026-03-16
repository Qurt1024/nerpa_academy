import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

// ─── Language Cubit ───────────────────────────────────────────────────────────

class LanguageCubit extends Cubit<AppLanguage> {
  static const _prefKey = 'app_language';

  LanguageCubit() : super(AppLanguage.english);

  /// Load persisted language on startup
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'en';
    emit(AppLanguageExtension.fromCode(code));
  }

  /// Change language and persist it
  Future<void> changeLanguage(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.code);
    emit(lang);
  }
}

// ─── Extension for easy access from BuildContext ──────────────────────────────

extension L10nContext on BuildContext {
  AppLocalizations get l10n {
    try {
      final lang = BlocProvider.of<LanguageCubit>(this, listen: false).state;
      return AppLocalizations(lang);
    } catch (_) {
      return const AppLocalizations(AppLanguage.english);
    }
  }
}
