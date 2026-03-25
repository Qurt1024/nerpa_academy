import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

/// Wraps the result of a Google sign-in so we know if the user is brand new
class GoogleSignInResult {
  final UserModel user;
  final bool isNewUser;
  const GoogleSignInResult({required this.user, required this.isNewUser});
}

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
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  /// Returns both the user AND whether they are a new sign-up
  Future<GoogleSignInResult> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Check if a Firestore document already exists for this user
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      final user = UserModel.fromMap(doc.data()!);
      // isNewUser = true if they somehow ended up with no subjects (edge case)
      return GoogleSignInResult(user: user, isNewUser: user.selectedSubjectIds.isEmpty);
    }

    // Brand new Google user — create a Firestore doc with empty subjects
    final newUser = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      // selectedSubjectIds is empty — they must go through subject selection
    );
    await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
    return GoogleSignInResult(user: newUser, isNewUser: true);
  }

  /// Called after subject selection for Google users
  Future<UserModel> saveSubjectsAndLanguage({
    required String uid,
    required List<String> subjectIds,
    required String appLanguage,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'selectedSubjectIds': subjectIds,
      'appLanguage': appLanguage,
    });
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateSelectedSubjects(String uid, List<String> subjectIds) async {
    await _firestore.collection('users').doc(uid).update({
      'selectedSubjectIds': subjectIds,
    });
  }

  Future<void> updateAppLanguage(String uid, String languageCode) async {
    await _firestore.collection('users').doc(uid).update({
      'appLanguage': languageCode,
    });
  }

  Future<void> addCompletedLesson(String uid, String lessonId, int score) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final completed = List<String>.from(data['completedLessons'] ?? []);
    if (!completed.contains(lessonId)) completed.add(lessonId);
    final currentScore = (data['totalScore'] as num?)?.toInt() ?? 0;
    await _firestore.collection('users').doc(uid).update({
      'completedLessons': completed,
      'totalScore': currentScore + score,
    });
  }

  Future<UserModel> _fetchOrCreateUser(User firebaseUser) async {
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(firebaseUser.uid).set(userModel.toMap());
    return userModel;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Permanently deletes the user's Firestore data and Firebase Auth account.
  /// For email/password users this works directly.
  /// For Google users the Google token must still be valid (recent sign-in).
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    // Delete Firestore document first
    await _firestore.collection('users').doc(uid).delete();
    // Delete Firebase Auth account
    await user.delete();
    // Sign out of Google session if applicable
    await _googleSignIn.signOut();
  }
}
