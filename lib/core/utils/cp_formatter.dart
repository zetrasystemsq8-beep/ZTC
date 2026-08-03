/// Formats a raw cent balance into NigerGram's CP/cent display,
/// per the rule: 1000 cents = 1 CP. This is display-only — the
/// stored number in Firestore/coinBalance is always the raw cent
/// count, never divided.
class CpFormatter {
  static const int centsPerCp = 1000;

  /// e.g. 12460 -> "12 CP, 460 cent"
  static String format(int rawCents) {
    final cp = rawCents ~/ centsPerCp;
    final remainder = rawCents % centsPerCp;
    if (cp == 0) return '$remainder cent';
    if (remainder == 0) return '$cp CP';
    return '$cp CP, $remainder cent';
  }
}
