import 'package:equatable/equatable.dart';

/// Тип вопроса в квизе.
///
/// [selectOption] — пользователь выбирает один из вариантов ответа
///   (экран «Select option type of question» из макета).
/// [typeAnswer]   — пользователь вводит ответ вручную
///   (экран «Input type of question» из макета).
enum QuestionType {
  selectOption,
  typeAnswer;

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionType.selectOption,
    );
  }
}

/// Модель вопроса внутри урока.
///
/// Хранится в подколлекции:
/// subjects/{subjectId}/lessons/{lessonId}/questions/{questionId}
///
/// В зависимости от [type]:
/// - [QuestionType.selectOption]: используется [options] и [correctOptionIndex].
/// - [QuestionType.typeAnswer]:   используется [correctAnswer].
class QuestionModel extends Equatable {
  /// Уникальный идентификатор.
  final String id;

  /// ID урока-родителя.
  final String lessonId;

  /// Текст вопроса.
  final String questionText;

  /// Тип вопроса (выбор / ввод текста).
  final QuestionType type;

  /// Порядок вопроса в уроке.
  final int order;

  // ── Поля для QuestionType.selectOption ────────────────────────

  /// Варианты ответа (обычно 4 штуки согласно макету).
  final List<String> options;

  /// Индекс правильного варианта в [options].
  final int correctOptionIndex;

  // ── Поля для QuestionType.typeAnswer ──────────────────────────

  /// Правильный ответ (сравнивается без учёта регистра).
  final String correctAnswer;

  const QuestionModel({
    required this.id,
    required this.lessonId,
    required this.questionText,
    required this.type,
    required this.order,
    this.options = const [],
    this.correctOptionIndex = 0,
    this.correctAnswer = '',
  });

  bool get isSelectOption => type == QuestionType.selectOption;
  bool get isTypeAnswer => type == QuestionType.typeAnswer;

  factory QuestionModel.fromJson(
    Map<String, dynamic> json,
    String docId,
    String lessonId,
  ) {
    return QuestionModel(
      id: docId,
      lessonId: lessonId,
      questionText: json['questionText'] as String? ?? '',
      type: QuestionType.fromString(json['type'] as String? ?? ''),
      order: json['order'] as int? ?? 0,
      options: List<String>.from(json['options'] as List? ?? []),
      correctOptionIndex: json['correctOptionIndex'] as int? ?? 0,
      correctAnswer: json['correctAnswer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'questionText': questionText,
        'type': type.name,
        'order': order,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
        'correctAnswer': correctAnswer,
      };

  /// Проверяет правильность ответа.
  /// Для [QuestionType.selectOption] принимает индекс (int).
  /// Для [QuestionType.typeAnswer] принимает строку (String).
  bool checkAnswer(dynamic answer) {
    if (isSelectOption) {
      return answer == correctOptionIndex;
    } else {
      return (answer as String).trim().toLowerCase() ==
          correctAnswer.trim().toLowerCase();
    }
  }

  @override
  List<Object?> get props => [
        id,
        lessonId,
        questionText,
        type,
        order,
        options,
        correctOptionIndex,
        correctAnswer,
      ];
}
