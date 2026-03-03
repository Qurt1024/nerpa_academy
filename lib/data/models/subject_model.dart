import 'package:equatable/equatable.dart';

/// Модель учебного предмета (Math, Informatics, Natural Science и т.д.)
///
/// Хранится в Firestore в коллекции [CollectionNames.subjects].
/// Пользователь выбирает предметы при регистрации (Sign Up 2),
/// после чего они сохраняются в его профиле.
class SubjectModel extends Equatable {
  /// Уникальный идентификатор документа в Firestore.
  final String id;

  /// Отображаемое название предмета (например, «Math»).
  final String title;

  /// Порядок отображения в списке (чем меньше, тем выше).
  final int order;

  const SubjectModel({
    required this.id,
    required this.title,
    required this.order,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json, String docId) {
    return SubjectModel(
      id: docId,
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'order': order,
      };

  @override
  List<Object?> get props => [id, title, order];
}
