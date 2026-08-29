import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/employee.dart';
import '../../../shared/widgets/form_helpers.dart';
import '../viewmodel/employees_notifier.dart';

/// Add or edit an employee. Pass [existing] to edit; null to create.
/// Opens as a modal bottom sheet on mobile, and a dialog on desktop
/// (caller decides via [showEmployeeForm]).
class EmployeeForm extends ConsumerStatefulWidget {
  final Employee? existing;
  const EmployeeForm({super.key, this.existing});

  @override
  ConsumerState<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late String _fullName;
  late String _employeeCode;
  String? _position;
  String? _phone;
  String? _email;
  String? _nationalId;
  late DateTime _hireDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _fullName = e?.fullName ?? '';
    _employeeCode = e?.employeeCode ?? '';
    _position = e?.position;
    _phone = e?.phone;
    _email = e?.email;
    _nationalId = e?.nationalId;
    _hireDate = e?.hireDate ?? DateTime.now();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    try {
      final notifier = ref.read(employeesProvider.notifier);
      if (widget.existing == null) {
        await notifier.addEmployee(buildNewEmployee(
          fullName: _fullName,
          employeeCode: _employeeCode,
          position: _position,
          nationalId: _nationalId,
          phone: _phone,
          email: _email,
          hireDate: _hireDate,
        ));
      } else {
        await notifier.updateEmployee(widget.existing!.copyWith(
          fullName: _fullName,
          position: _position,
          phone: _phone,
          email: _email,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isEdit ? 'Edit Employee' : 'Add Employee',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            formTextField(
              label: 'Full Name',
              initialValue: _fullName,
              required: true,
              onSaved: (v) => _fullName = v!.trim(),
            ),
            formTextField(
              label: 'Employee Code',
              hint: 'e.g. EMP-1001',
              initialValue: _employeeCode,
              required: true,
              onSaved: (v) => _employeeCode = v!.trim(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Employee code is required';
                return null;
              },
            ),
            formTextField(
              label: 'Position / Trade',
              initialValue: _position,
              onSaved: (v) => _position = v?.trim(),
            ),
            formTextField(
              label: 'National ID',
              initialValue: _nationalId,
              onSaved: (v) => _nationalId = v?.trim(),
            ),
            formTextField(
              label: 'Phone',
              initialValue: _phone,
              keyboardType: TextInputType.phone,
              onSaved: (v) => _phone = v?.trim(),
            ),
            formTextField(
              label: 'Email',
              initialValue: _email,
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _email = v?.trim(),
            ),
            formDateField(
              context: context,
              label: 'Hire Date',
              value: _hireDate,
              required: true,
              onPicked: (d) => setState(() => _hireDate = d),
            ),
            const SizedBox(height: 8),
            formActions(context: context, saving: _saving, onSave: _save),
          ],
        ),
      ),
    );
  }
}

Future<void> showEmployeeForm(BuildContext context, {Employee? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => EmployeeForm(existing: existing),
  );
}
