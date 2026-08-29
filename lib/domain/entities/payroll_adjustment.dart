import '../enums/enums.dart';
import '../value_objects/money.dart';

/// A post-finalization correction against an already-finalized payroll
/// record. Adjustments are additive and auditable — they never rewrite a
/// locked [PayrollRecord]'s original figures (architecture §2, §15).
class PayrollAdjustment {
  final String id;
  final String payrollRecordId;
  final AdjustmentType type;
  final Money amount;
  final String reason;
  final String createdBy;
  final DateTime createdAt;

  const PayrollAdjustment({
    required this.id,
    required this.payrollRecordId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
  });
}
