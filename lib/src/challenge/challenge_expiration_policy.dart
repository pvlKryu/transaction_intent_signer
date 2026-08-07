/// Policy describing how challenge expiration is evaluated.
class ChallengeExpirationPolicy {
  /// Creates a [ChallengeExpirationPolicy].
  const ChallengeExpirationPolicy({
    this.clockSkewTolerance = Duration.zero,
  });

  /// Allowed clock skew when comparing [expiresAt] to "now".
  final Duration clockSkewTolerance;

  /// Returns true when [expiresAt] is considered expired at [now].
  bool isExpired(DateTime expiresAt, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toUtc();
    final effectiveExpiry = expiresAt.toUtc().add(clockSkewTolerance);
    return !reference.isBefore(effectiveExpiry);
  }
}
