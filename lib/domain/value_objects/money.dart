/// Money is stored as integer minor units (e.g. fils/cents) to avoid the
/// classic floating-point rounding drift that is unacceptable in payroll.
/// All arithmetic in the payroll engine should go through this type rather
/// than raw `double`.
class Money {
  /// Amount in minor units (e.g. cents, fils). 2 decimal places assumed.
  final int minorUnits;
  final String currency;

  const Money(this.minorUnits, this.currency);

  factory Money.fromMajor(double major, String currency) =>
      Money((major * 100).round(), currency);

  factory Money.zero(String currency) => Money(0, currency);

  double get major => minorUnits / 100.0;

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw StateError(
        'Currency mismatch: $currency vs ${other.currency}. '
        'Cross-currency payroll arithmetic must be handled explicitly '
        'via an FX conversion step, never implicitly.',
      );
    }
  }

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator *(num factor) => Money((minorUnits * factor).round(), currency);

  Money operator /(num divisor) => Money((minorUnits / divisor).round(), currency);

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return minorUnits < other.minorUnits;
  }

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return minorUnits > other.minorUnits;
  }

  bool get isNegative => minorUnits < 0;

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits && other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '${major.toStringAsFixed(2)} $currency';
}
