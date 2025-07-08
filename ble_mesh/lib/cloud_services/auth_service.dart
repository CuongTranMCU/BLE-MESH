import 'package:ble_mesh/cloud_services/rtdb_service_account.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Create user object based on FirebaseUser
  Future<UserModels?> _userFromFirebaseUser(User? user) async {
    if (user != null) {
      String? role = await RTDBServiceAccount(uid: user.uid).getUserdata("role");
      return UserModels(
        uid: user.uid,
        email: user.email,
        role: role,
        emailVerify: user.emailVerified,
      );
    } else {
      return null;
    }
  }

  // Authentication change user stream
  Stream<UserModels?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((User? user) async {
      if (user != null) {
        await user.reload();
        user = _firebaseAuth.currentUser; // Cập nhật lại sau reload
      }
      return await _userFromFirebaseUser(user);
    });
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  Future<String?> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await _userFromFirebaseUser(user);
        return null; // Null đại diện cho đăng nhập thành công
      } else {
        return "Unexpected error: No user returned after successful login";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No User Found for that Email";
      } else if (e.code == 'wrong-password') {
        return "Wrong Password";
      } else {
        return "Error: ${e.code}";
      }
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

// Register with email & password
  Future<UserModels> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String userName,
    required String role,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await RTDBServiceAccount(uid: user.uid).updateUserData(email, userName, role);
        return await _userFromFirebaseUser(user) as UserModels;
      } else {
        throw FirebaseAuthException(code: 'user-creation-failed', message: 'User creation failed');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseErrorToMessage(e.code));
    }
  }

  String _mapFirebaseErrorToMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Weak Password';
      case 'email-already-in-use':
        return 'Email Already in Use';
      default:
        return 'Error: $code';
    }
  }

  // Not OK
// Update Email
  Future updateEmail(String email, String password, String newEmail) async {
    try {
      //await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        AuthCredential credential = EmailAuthProvider.credential(email: currentUser.email!, password: password);

        // Xác thực người dùng bằng mật khẩu hiện tại
        await currentUser.reauthenticateWithCredential(credential);

        // Nếu xác thực thành công, thực hiện cập nhật email
        await currentUser.updateEmail(newEmail);
      }
    } on FirebaseAuthException catch (e) {
      print("Error updating email: ${e.toString()}");
      throw e;
    }
  }

  // Update Password
  Future updatePassword(String email, String password, String newPassword) async {
    try {
      // await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        AuthCredential credential = EmailAuthProvider.credential(email: currentUser.email!, password: password);

        // Xác thực người dùng bằng mật khẩu hiện tại
        await currentUser.reauthenticateWithCredential(credential);

        // Nếu xác thực thành công, thực hiện cập nhật mật khẩu
        await currentUser.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      print("Error updating password: ${e.toString()}");
      throw e;
    }
  }

  Future sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      print("Error send Email verification: ${e.toString()}");
      throw e;
    }
  }

  // Reset Password
  Future resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      print("Error reset password: ${e.toString()}");
      return e;
    }
  }

  //Sign out
  Future signOut() async {
    try {
      return await _firebaseAuth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
