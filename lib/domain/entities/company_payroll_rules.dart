import '../enums/enums.dart';

/// A single configured overtime rule. Company rules can combine multiple
/// of these keyed by [dayType] (architecture §14: "make OT rules
/// configurable, with explicit rule types").
class OvertimeRule {
  final DayType dayType;
  final OvertimeRuleType type;

  /// Meaning depends on [type]:
  /// - fixedHourlyRate: flat amount per OT hour, in major currency units.
  /// - multiplierOfBaseHourlyRate: multiplier applied to derived base
  ///   hourly rate (e.g. 1.5, 2.0).
  /// - weekendHolidayRate: flat amount per OT hour for that day type.
  final double value;

  const OvertimeRule({required this.dayType, required this.type, required this.value});
}

/// Company-wide, configurable payroll settings. NONE of these should be
/// hard-coded in the calculation engine (architecture §2, §39) — they are
/// injected as input so a different company/tenant can run the exact same
/// engine with different numbers.
///
/// The defaults provided in [CompanyPayrollRules.placeholderDefaults] are
/// NOT statutory advice and must be confirmed against the real company
/// policy before production (architecture §14, §45).
class CompanyPayrollRules {
  final String currency;
  final double standardHoursPerDay;
  final int standardWorkingDaysPerMonth; // used to derive a daily rate from a monthly salary
  final Set<int> weekendWeekdays; // DateTime.weekday values, e.g. {6, 7} = Sat/Sun
  final List<OvertimeRule> overtimeRules;
  final int roundingDecimalPlaces;

  const CompanyPayrollRules({
    required this.currency,
    required this.standardHoursPerDay,
    required this.standardWorkingDaysPerMonth,
    required this.weekendWeekdays,
    required this.overtimeRules,
    this.roundingDecimalPlaces = 2,
  });

  OvertimeRule? ruleFor(DayType dayType) {
    for (final r in overtimeRules) {
      if (r.dayType == dayType) return r;
    }
    return null;
  }

  /// A clearly-labelled placeholder configuration for local/mock
  /// development ONLY. Every value here is a business question listed in
  /// architecture §45 and must be confirmed before this ships to
  /// production payroll.
  static CompanyPayrollRules placeholderDefaults({String currency = 'AED'}) {
    return CompanyPayrollRules(
      currency: currency,
      standardHoursPerDay: 8,
      standardWorkingDaysPerMonth: 30,
      weekendWeekdays: {DateTime.friday},
      overtimeRules: const [
        OvertimeRule(
          dayType: DayType.regular,
          type: OvertimeRuleType.multiplierOfBaseHourlyRate,
          value: 1.25,
        ),
        OvertimeRule(
          dayType: DayType.weekend,
          type: OvertimeRuleType.multiplierOfBaseHourlyRate,
          value: 1.5,
        ),
        OvertimeRule(
          dayType: DayType.publicHoliday,
          type: OvertimeRuleType.multiplierOfBaseHourlyRate,
          value: 2.0,
        ),
      ],
    );
  }
}
