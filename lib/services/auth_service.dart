import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();

    return snapshot.exists && data?['role'] == 'admin';
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final snapshot = await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (!snapshot.exists || snapshot.data()?['role'] != 'admin') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'not-admin',
        message: 'Bu hesabın yönetici yetkisi bulunmuyor.',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();
}
