import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class ContentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Subjects ──────────────────────────────────────────────────────────────
  // SubjectModel stores ALL language titles internally and resolves them at
  // display time via subject.localTitle(langCode). No langCode needed here.

  Future<List<SubjectModel>> fetchAllSubjects() async {
    final snap = await _db
        .collection('subjects')
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => SubjectModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<SubjectModel>> fetchSubjectsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _db
        .collection('subjects')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snap.docs
        .map((d) => SubjectModel.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // ── Lessons ───────────────────────────────────────────────────────────────
  // LessonModel resolves the correct language at parse time so the title and
  // theory text are immediately ready for display.

  Future<List<LessonModel>> fetchLessonsForSubject(
    String subjectId, {
    String langCode = 'en',
  }) async {
    final snap = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('lessons')
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => LessonModel.fromMap(d.id, d.data(), langCode: langCode))
        .toList();
  }

  Future<LessonModel?> fetchLesson(
    String lessonId,
    String subjectId, {
    String langCode = 'en',
  }) async {
    final doc = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('lessons')
        .doc(lessonId)
        .get();
    if (!doc.exists) return null;
    return LessonModel.fromMap(doc.id, doc.data()!, langCode: langCode);
  }

  // ── Questions ─────────────────────────────────────────────────────────────

  Future<List<QuestionModel>> fetchQuestionsForLesson(
    String lessonId,
    String subjectId, {
    String langCode = 'en',
  }) async {
    final snap = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('lessons')
        .doc(lessonId)
        .collection('questions')
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => QuestionModel.fromMap(d.id, d.data(), langCode: langCode))
        .toList();
  }
}
