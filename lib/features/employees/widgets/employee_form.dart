import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/nexus_widgets.dart';
import '../../../domain/entities/employee.dart';
import '../viewmodel/employees_notifier.dart';

class EmployeeForm extends ConsumerStatefulWidget {
  final Employee? existing;
  const EmployeeForm({super.key, this.existing});

  @override
  ConsumerState<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late String _fullName, _employeeCode;
  String? _position, _phone, _email, _nationalId;
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
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: const Color(0xFFE84646)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NexusFormSheet(
      title: widget.existing == null ? 'Add Employee' : 'Edit Employee',
      subtitle: widget.existing == null
          ? 'New employee record — all fields marked * are required.'
          : 'Update details. Employee code cannot be changed after creation.',
      form: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            nexusTextField(
                label: 'Full Name',
                initialValue: _fullName,
                required: true,
                onSaved: (v) => _fullName = v!.trim()),
            nexusTextField(
                label: 'Employee Code',
                hint: 'e.g. EMP-1001',
                initialValue: _employeeCode,
                required: true,
                onSaved: (v) => _employeeCode = v!.trim()),
            nexusTextField(
                label: 'Position / Trade',
                initialValue: _position,
                onSaved: (v) => _position = v?.trim()),
            nexusTextField(
                label: 'National ID',
                initialValue: _nationalId,
                onSaved: (v) => _nationalId = v?.trim()),
            nexusTextField(
                label: 'Phone',
                initialValue: _phone,
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v?.trim()),
            nexusTextField(
                label: 'Email',
                initialValue: _email,
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _email = v?.trim()),
            nexusDateField(
                context: context,
                label: 'Hire Date',
                value: _hireDate,
                required: true,
                onPicked: (d) => setState(() => _hireDate = d)),
            const SizedBox(height: 8),
            nexusFormActions(
                context: context, saving: _saving, onSave: _save),
          ],
        ),
      ),
    );
  }
}

Future<void> showEmployeeForm(BuildContext context, {Employee? existing}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EmployeeForm(existing: existing),
    );
