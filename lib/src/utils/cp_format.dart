/// Shared CP <-> Cent conversion and formatting.
/// 1 CP = 1000 Cent (the smaller denomination, for low-value transfers
/// across the Zetra ecosystem — e.g. tips, micro-payments).
class CpFormat {
  CpFormat._();

  static const int centsPerCp = 1000;

  /// Converts a CP amount (e.g. 2.5) into whole Cent (e.g. 2500).
  static int cpToCents(double cp) => (cp * centsPerCp).round();

  /// Converts whole Cent (e.g. 2500) into CP (e.g. 2.5).
  static double centsToCp(int cents) => cents / centsPerCp;

  /// "2.50 CP (2500 Cent)"
  static String displayBoth(double cpAmount) {
    final cents = cpToCents(cpAmount);
    return '${cpAmount.toStringAsFixed(2)} CP ($cents Cent)';
  }

  /// "2.50 CP" only.
  static String displayCp(double cpAmount) => '${cpAmount.toStringAsFixed(2)} CP';

  /// "2500 Cent" only.
  static String displayCents(double cpAmount) => '${cpToCents(cpAmount)} Cent';
}

enum CpInputUnit { cp, cent }
