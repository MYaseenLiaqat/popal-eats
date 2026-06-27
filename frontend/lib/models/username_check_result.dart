/// Result of a live username availability check.
class UsernameCheckResult {
  const UsernameCheckResult._({
    this.available,
    this.errorMessage,
    this.validationMessage,
  });

  const UsernameCheckResult.available() : this._(available: true);

  const UsernameCheckResult.taken() : this._(available: false);

  const UsernameCheckResult.error([
    String message = 'Unable to verify username',
  ]) : this._(errorMessage: message);

  const UsernameCheckResult.invalid(String message)
      : this._(available: false, validationMessage: message);

  /// `true` = available, `false` = taken/invalid, `null` = check failed.
  final bool? available;
  final String? errorMessage;
  final String? validationMessage;

  bool get succeeded => errorMessage == null;
}
