import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_outcome.dart';
import '../models/behavioural_event.dart';

/// Thin REST client for the FastAPI backend (docs/api-contract.md).
///
/// Every persistence-backed endpoint currently returns 503 until
/// Supabase/PostgreSQL is configured — see backend/app/core/persistence.py.
/// Callers should branch on [ApiOutcome] and render [ApiPending] as a
/// clear "pending" state, not an error.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? apiBaseUrl,
        _client = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<ApiOutcome<ObservationAnalysisResult>> analyzeObservation(String text) async {
    final outcome = await _post('/api/v1/analyze-observation', {'text': text});
    return switch (outcome) {
      ApiSuccess(data: final body) =>
        ApiSuccess(ObservationAnalysisResult.fromJson(body)),
      ApiPending(message: final m) => ApiPending(m),
      ApiFailure(message: final m) => ApiFailure(m),
    };
  }

  Future<ApiOutcome<Map<String, dynamic>>> signUp({
    required String email,
    required String password,
  }) {
    return _post('/api/v1/auth/sign-up', {'email': email, 'password': password});
  }

  Future<ApiOutcome<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) {
    return _post('/api/v1/auth/login', {'email': email, 'password': password});
  }

  Future<ApiOutcome<Map<String, dynamic>>> createChild({
    required String displayName,
    String? dateOfBirthIso,
  }) {
    return _post('/api/v1/children', {
      'display_name': displayName,
      if (dateOfBirthIso != null) 'date_of_birth': dateOfBirthIso,
    });
  }

  Future<ApiOutcome<Map<String, dynamic>>> createObservationPeriod({
    required String childId,
    required DateTime startAt,
    int? durationDays,
  }) {
    return _post('/api/v1/observation-periods', {
      'child_id': childId,
      'start_at': startAt.toUtc().toIso8601String(),
      if (durationDays != null) 'duration_days': durationDays,
    });
  }

  Future<ApiOutcome<Map<String, dynamic>>> createObservation({
    required String childId,
    required String observationPeriodId,
    required String text,
    String? context,
    DateTime? observedAt,
  }) {
    return _post('/api/v1/observations', {
      'child_id': childId,
      'observation_period_id': observationPeriodId,
      'text': text,
      if (context != null) 'context': context,
      'observed_at': (observedAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
  }

  Future<ApiOutcome<List<dynamic>>> listObservations(String childId) async {
    final outcome = await _get('/api/v1/observations?child_id=$childId');
    return switch (outcome) {
      ApiSuccess(data: final body) => ApiSuccess(body['__list__'] as List<dynamic>),
      ApiPending(message: final m) => ApiPending(m),
      ApiFailure(message: final m) => ApiFailure(m),
    };
  }

  Future<ApiOutcome<Map<String, dynamic>>> createGuidedObservation({
    required String childId,
    required String observationPeriodId,
    required String domain,
    required String choice,
    String? note,
    String? context,
  }) {
    return _post('/api/v1/guided-observations', {
      'child_id': childId,
      'observation_period_id': observationPeriodId,
      'domain': domain,
      'choice': choice,
      if (note != null && note.isNotEmpty) 'note': note,
      if (context != null) 'context': context,
      'observed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<ApiOutcome<Map<String, dynamic>>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _interpret(response);
    } catch (error) {
      return ApiFailure('Could not reach the backend at $_baseUrl: $error');
    }
  }

  Future<ApiOutcome<Map<String, dynamic>>> _get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$path'))
          .timeout(const Duration(seconds: 10));
      // GET /observations returns a JSON array; wrap it so callers share
      // the same _interpret() status-code handling as the object routes.
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return ApiSuccess({'__list__': decoded});
      }
      return _interpret(response);
    } catch (error) {
      return ApiFailure('Could not reach the backend at $_baseUrl: $error');
    }
  }

  ApiOutcome<Map<String, dynamic>> _interpret(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ApiSuccess(jsonDecode(response.body) as Map<String, dynamic>);
    }
    if (response.statusCode == 503) {
      final detail = _detailOf(response) ?? 'This feature is pending Supabase configuration.';
      return ApiPending(detail);
    }
    if (response.statusCode == 422) {
      return ApiFailure(_validationMessage(response));
    }
    final detail = _detailOf(response) ?? 'Request failed (${response.statusCode}).';
    return ApiFailure(detail);
  }

  /// Turns FastAPI's 422 body into something a caregiver can act on.
  ///
  /// The raw body is a list of Pydantic error objects; rendering it
  /// directly put `[{type: string_too_long, loc: [body, text], ...}]` in
  /// front of the user.
  String _validationMessage(http.Response response) {
    const fallback = "That entry couldn't be submitted. Please check what you typed and try again.";
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return fallback;

      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is! List) return fallback;

      final reasons = <String>[];
      for (final item in detail) {
        if (item is Map<String, dynamic> && item['msg'] is String) {
          reasons.add(_humanizeReason(item['msg'] as String));
        }
      }
      if (reasons.isEmpty) return fallback;
      return "That entry couldn't be submitted: ${reasons.join('; ')}.";
    } catch (_) {
      return fallback;
    }
  }

  /// Pydantic messages are written for developers ("String should have at
  /// most 4000 characters"); soften the ones a caregiver can actually hit.
  String _humanizeReason(String message) {
    final match = RegExp(r'should have at most (\d+) characters').firstMatch(message);
    if (match != null) {
      return 'it is longer than the ${match.group(1)}-character limit';
    }
    if (message.contains('should have at least 1 character')) {
      return 'it is empty';
    }
    return message.replaceFirst('String', 'The text');
  }

  String? _detailOf(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Non-JSON body; fall through to the generic message.
    }
    return null;
  }
}
