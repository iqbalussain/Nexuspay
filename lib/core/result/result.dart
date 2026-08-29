/// A minimal typed Result used throughout the domain layer so use cases
/// return explicit success/failure instead of throwing for expected,
/// business-level failures (validation, locked period, missing rate, etc).
///
/// Deliberately dependency-free (no `dartz`/`fpdart`) so the domain layer
/// has zero external package dependencies, per the architecture's
/// "domain must not depend on anything Flutter/Supabase-specific" rule —
/// and, practically, so this code compiles/tests with a bare Dart SDK.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get value => (this as Success<T>).value;
  AppFailure get failure => (this as Failure<T>).failure;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    return failure((self as Failure<T>).failure);
  }

  static Result<T> ok<T>(T value) => Success<T>(value);
  static Result<T> err<T>(AppFailure failure) => Failure<T>(failure);
}

final class Success<T> extends Result<T> {
  @override
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  @override
  final AppFailure failure;
  const Failure(this.failure);
}

/// Base type for expected, business-meaningful failures.
class AppFailure {
  final String code;
  final String message;
  const AppFailure(this.code, this.message);

  @override
  String toString() => 'AppFailure($code: $message)';
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(String message) : super('validation_error', message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(String message) : super('not_found', message);
}

class PeriodLockedFailure extends AppFailure {
  const PeriodLockedFailure(String message) : super('period_locked', message);
}

class MissingRateFailure extends AppFailure {
  const MissingRateFailure(String message) : super('missing_rate', message);
}
