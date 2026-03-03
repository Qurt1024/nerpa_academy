import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Модель пользователя — расширена полями для обучения.
///
/// Новые поля по сравнению с исходной версией:
/// - [selectedSubjectIds] — список ID предметов, выбранных на экране Sign Up 2.
/// - [hearts] — количество жизней (аналог Duolingo); при ошибке в квизе уменьшается.
class UserModel extends Equatable {
  /// Уникальный идентификатор (совпадает с uid в FirebaseAuth).
  final String uid;

  /// Отображаемое имя.
  final String displayName;

  /// Email пользователя.
  final String email;

  /// URL аватара (может быть пустой строкой).
  final String photoUrl;

  /// ID предметов, выбранных пользователем при регистрации.
  /// Показываются на главном экране как список карточек.
  final List<String> selectedSubjectIds;

  /// Текущее количество жизней (hearts).
  /// Максимум определяется в [AppConstants.maxHearts].
  /// При ошибке в квизе уменьшается на 1.
  final int hearts;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.selectedSubjectIds = const [],
    this.hearts = 5,
  });

  /// Пустой пользователь — используется как дефолтное значение
  /// вместо `null`.
  static const UserModel empty = UserModel(
    uid: '',
    displayName: '',
    email: '',
    photoUrl: '',
  );

  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;

  // ── Фабрики ──────────────────────────────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      selectedSubjectIds:
          List<String>.from(json['selectedSubjectIds'] as List? ?? []),
      hearts: json['hearts'] as int? ?? 5,
    );
  }

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'selectedSubjectIds': selectedSubjectIds,
        'hearts': hearts,
      };

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    List<String>? selectedSubjectIds,
    int? hearts,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      selectedSubjectIds: selectedSubjectIds ?? this.selectedSubjectIds,
      hearts: hearts ?? this.hearts,
    );
  }

  @override
  List<Object?> get props =>
      [uid, displayName, email, photoUrl, selectedSubjectIds, hearts];
}
