import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchOrCreateUser(credential.user!);
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required List<String> subjectIds,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final userModel = UserModel(
      uid: user.uid,
      email: email,
      selectedSubjectIds: subjectIds,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _fetchOrCreateUser(userCredential.user!);
  }

  Future<UserModel> _fetchOrCreateUser(User firebaseUser) async {
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userModel.toMap());
    return userModel;
  }

  Future<UserModel?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateSelectedSubjects(
      String uid, List<String> subjectIds) async {
    await _firestore.collection('users').doc(uid).update({
      'selectedSubjectIds': subjectIds,
    });
  }

  Future<void> addCompletedLesson(String uid, String lessonId, int score) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final completed = List<String>.from(data['completedLessons'] ?? []);
    if (!completed.contains(lessonId)) {
      completed.add(lessonId);
    }
    final currentScore = (data['totalScore'] as num?)?.toInt() ?? 0;
    await _firestore.collection('users').doc(uid).update({
      'completedLessons': completed,
      'totalScore': currentScore + score,
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
