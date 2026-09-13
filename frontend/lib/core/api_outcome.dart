/// Result of one backend call. `ApiPending` specifically represents the
/// 503 "Supabase not configured yet" response that every persistence-
/// backed endpoint currently returns (see docs/api-contract.md) — screens
/// show it as a clear, non-error "pending" state rather than a failure.
sealed class ApiOutcome<T> {
  const ApiOutcome();
}

class ApiSuccess<T> extends ApiOutcome<T> {
  const ApiSuccess(this.data);
  final T data;
}

class ApiPending<T> extends ApiOutcome<T> {
  const ApiPending(this.message);
  final String message;
}

class ApiFailure<T> extends ApiOutcome<T> {
  const ApiFailure(this.message);
  final String message;
}
