import 'dart:async';

import 'package:asd_nlp_screening_app/core/api_outcome.dart';
import 'package:asd_nlp_screening_app/core/auth_service.dart';

/// In-memory AuthService for widget tests.
///
/// `supabase_flutter` reads a global singleton that cannot be initialised
/// in a widget test, so tests drive the screens through this instead.
class FakeAuthService implements AuthService {
  FakeAuthService({bool signedIn = false, this.email})
      : _signedIn = signedIn;

  final _controller = StreamController<bool>.broadcast();
  bool _signedIn;
  String? email;

  /// Recorded calls, so tests can assert what the screen submitted.
  final List<String> calls = [];
  ApiOutcome<String> signUpResult = const ApiSuccess('user-id');
  ApiOutcome<String> signInResult = const ApiSuccess('user-id');

  @override
  Stream<bool> get signedInChanges => _controller.stream;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get currentEmail => email;

  @override
  Future<ApiOutcome<String>> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp:$email');
    if (signUpResult is ApiSuccess<String>) emitSignedIn(true);
    return signUpResult;
  }

  @override
  Future<ApiOutcome<String>> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn:$email');
    if (signInResult is ApiSuccess<String>) emitSignedIn(true);
    return signInResult;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    emitSignedIn(false);
  }

  void emitSignedIn(bool value) {
    _signedIn = value;
    _controller.add(value);
  }

  void dispose() => _controller.close();
}
