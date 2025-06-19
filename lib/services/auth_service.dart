import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  static Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Attempting to register with email: $email');
      
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update user profile with name
        await userCredential.user?.updateDisplayName(name);

        // Save user info to Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Registration successful for user: ${userCredential.user?.uid}');
        return null; // Success
      } catch (e) {
        // Handle the specific PigeonUserDetails type casting error
        if (e.toString().contains('PigeonUserDetails')) {
          print('PigeonUserDetails type casting error caught during registration, but auth likely succeeded');
          // Wait a moment for Firebase to update auth state
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Check if user is now registered
          if (_auth.currentUser != null && _auth.currentUser!.email == email) {
            print('User registration succeeded despite the error');
            
            // Try to save user data to Firestore even after the error
            try {
              await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
                'name': name,
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
              });
              print('User data saved to Firestore successfully');
            } catch (firestoreError) {
              print('Error saving to Firestore: $firestoreError');
            }
            
            return null; // Success despite the error
          }
        }
        rethrow; // Re-throw if it's not the specific error we're handling
      }
      
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error in registration: ${e.code} - ${e.message}');
      return _handleAuthError(e);
    } catch (e) {
      print('General Error in registration: $e');
      
      // Special handling for the PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        print('Handling PigeonUserDetails error during registration - checking if auth actually succeeded');
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (_auth.currentUser != null && _auth.currentUser!.email == email) {
          print('Registration succeeded despite type casting error');
          
          // Try to save user data to Firestore
          try {
            await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
              'name': name,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (firestoreError) {
            print('Error saving to Firestore after error recovery: $firestoreError');
          }
          
          return null; // Success
        }
      }
      
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Sign in with email and password
  static Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to sign in with email: $email');
      
      // Check if the same user is already signed in
      if (_auth.currentUser != null && _auth.currentUser!.email == email) {
        print('User with this email is already signed in');
        return null; // Already signed in with the same account, consider it success
      }
      
      // Sign out first if a different user is signed in
      if (_auth.currentUser != null) {
        print('Different user signed in, signing out first...');
        await _auth.signOut();
        // Add a small delay to ensure sign out completes
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        print('Sign in successful for user: ${userCredential.user?.uid}');
        return null; // Success
      } catch (e) {
        // Handle the specific PigeonUserDetails type casting error
        if (e.toString().contains('PigeonUserDetails')) {
          print('PigeonUserDetails type casting error caught, but auth likely succeeded');
          // Wait a moment for Firebase to update auth state
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Check if user is now signed in
          if (_auth.currentUser != null && _auth.currentUser!.email == email) {
            print('User is now signed in despite the error');
            return null; // Success despite the error
          }
        }
        rethrow; // Re-throw if it's not the specific error we're handling
      }
      
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error in sign in: ${e.code} - ${e.message}');
      return _handleAuthError(e);
    } catch (e) {
      print('General Error in sign in: $e');
      
      // Special handling for the PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        print('Handling PigeonUserDetails error - checking if auth actually succeeded');
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (_auth.currentUser != null && _auth.currentUser!.email == email) {
          print('Authentication succeeded despite type casting error');
          return null; // Success
        }
      }
      
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Sign out
  static Future<String?> signOut() async {
    try {
      await _auth.signOut();
      print('Sign out successful');
      return null; // Success
    } catch (e) {
      print('Error in sign out: $e');
      return 'Failed to sign out: ${e.toString()}';
    }
  }

  // Reset password
  static Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error in password reset: ${e.code} - ${e.message}');
      return _handleAuthError(e);
    } catch (e) {
      print('General Error in password reset: $e');
      return 'Failed to send password reset email: ${e.toString()}';
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Handle Firebase Auth errors
  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
} 