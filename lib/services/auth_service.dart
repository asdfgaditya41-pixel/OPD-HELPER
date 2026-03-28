import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized) {
      await _googleSignIn.initialize();
      _isGoogleInitialized = true;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // 1. Trigger the Google authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 3. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with the Google UserCredential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // 6. Sync user data to your Firestore database
      await _syncUserToFirestore(userCredential.user);
      
      return userCredential;
    } catch (e) {
      // Print or log the error for debugging
      print("Error in signInWithGoogle: $e");
      rethrow; // Let the calling UI handle the exception to show a snackbar/alert
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      await _syncUserToFirestore(userCredential.user, customName: name);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> _syncUserToFirestore(User? user, {String? customName}) async {
    if (user == null) return;
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    // Only create profile on first login to avoid overriding custom edits
    if (!doc.exists) {
      final appUser = AppUser(
        id: user.uid,
        name: customName ?? user.displayName ?? "New User",
        email: user.email ?? "",
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await docRef.set(appUser.toMap());
    } else if (customName != null && doc.data()?['name'] == '') {
      await docRef.update({'name': customName});
    }
  }
}
