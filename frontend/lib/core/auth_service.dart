import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_outcome.dart';

/// Caregiver authentication.
///
/// An interface rather than calling Supabase directly from the widgets:
/// `supabase_flutter` reads a global singleton that cannot be initialised
/// in a widget test, so screens depend on this and tests supply a fake.
/// Only auth lives here — persistence is Step 2.
abstract class AuthService {
  /// Emits whenever the caregiver signs in or out.
  Stream<bool> get signedInChanges;

  bool get isSignedIn;

  /// Email of the signed-in caregiver, for display.
  String? get currentEmail;

  /// On success carries the user id. With email confirmation disabled the
  /// caregiver is signed in immediately, and the database trigger has
  /// already created their `caregivers` row.
  Future<ApiOutcome<String>> signUp({
    required String email,
    required String password,
  });

  Future<ApiOutcome<String>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({GoTrueClient? auth})
      : _auth = auth ?? Supabase.instance.client.auth;

  final GoTrueClient _auth;

  @override
  Stream<bool> get signedInChanges =>
      _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Future<ApiOutcome<String>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) {
        return const ApiFailure('Sign-up did not return an account.');
      }
      if (response.session == null) {
        // Email confirmation is enabled on the project; the caregiver
        // cannot continue until they confirm.
        return const ApiFailure(
          'Account created. Confirm your email address, then log in.',
        );
      }
      return ApiSuccess(user.id);
    } on AuthException catch (error) {
      return ApiFailure(error.message);
    } catch (error) {
      return ApiFailure('Could not reach Supabase: $error');
    }
  }

  @override
  Future<ApiOutcome<String>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response =
          await _auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) {
        return const ApiFailure('Incorrect email or password.');
      }
      return ApiSuccess(user.id);
    } on AuthException catch (error) {
      return ApiFailure(error.message);
    } catch (error) {
      return ApiFailure('Could not reach Supabase: $error');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
