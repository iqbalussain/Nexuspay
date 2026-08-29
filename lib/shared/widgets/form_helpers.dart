import 'package:flutter/material.dart';

/// Reusable form field builders used across every CRUD form in the app.
/// Keeping them here means every module gets consistent padding, error
/// display, and styling automatically — change once, all forms update.

Widget formTextField({
  required String label,
  String? hint,
  String? initialValue,
  bool required = false,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  void Function(String?)? onSaved,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onSaved: onSaved,
      validator:
          validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null
              : null),
    ),
  );
}

Widget formDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  bool required = false,
  void Function(T?)? onChanged,
  String? Function(T?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      validator:
          validator ??
          (required ? (v) => v == null ? '$label is required' : null : null),
    ),
  );
}

Widget formDateField({
  required BuildContext context,
  required String label,
  required DateTime? value,
  DateTime? firstDate,
  DateTime? lastDate,
  bool required = false,
  required void Function(DateTime) onPicked,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value != null
              ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
              : 'Select date',
          style: TextStyle(color: value != null ? null : Colors.grey),
        ),
      ),
    ),
  );
}

/// Standard form action row: Cancel + Save.
Widget formActions({
  required BuildContext context,
  required bool saving,
  required VoidCallback onSave,
  String saveLabel = 'Save',
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: saving ? null : onSave,
        child: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(saveLabel),
      ),
    ],
  );
}
