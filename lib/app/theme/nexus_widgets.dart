import 'package:flutter/material.dart';

import 'nexus_theme.dart';

// ---- Section header with left-border accent --------------------------

/// The signature design element: a 2px left-border in the module accent
/// colour + a small SCREAMING label above the actual page title.
class NexusSectionHeader extends StatelessWidget {
  final String eyebrow; // e.g. "MASTER DATA"
  final String title;
  final Color accentColor;
  final Widget? trailing;

  const NexusSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.accentColor = NexusColors.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left accent rule — the signature element
        Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: NexusTypography.label),
              const SizedBox(height: 2),
              Text(title, style: NexusTypography.displayMedium),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---- Stat card for dashboard / summary rows --------------------------

class NexusStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color accentColor;
  final bool isMonetary;

  const NexusStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    this.accentColor = NexusColors.primary,
    this.isMonetary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NexusSpacing.md),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        borderRadius: NexusRadius.sm,
        border: Border.all(color: NexusColors.border),
        // Subtle top accent line instead of a card shadow
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.06), NexusColors.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label.toUpperCase(), style: NexusTypography.label),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: isMonetary
                ? NexusTypography.money(fontSize: 22, weight: FontWeight.w700)
                : NexusTypography.displayMedium.copyWith(color: accentColor),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(subValue!, style: NexusTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ---- Status badge (replaces the plain Chip from Phase 3) -------------

class NexusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const NexusBadge({
    super.key,
    required this.label,
    required this.color,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: NexusRadius.chip,
        border: Border.all(color: color.withOpacity(0.35), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Search bar -------------------------------------------------------

class NexusSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const NexusSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: NexusTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(
          Icons.search,
          size: 16,
          color: NexusColors.textMuted,
        ),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 14,
                  color: NexusColors.textMuted,
                ),
                onPressed: () {
                  controller?.clear();
                  onChanged('');
                },
              )
            : null,
      ),
      onChanged: onChanged,
    );
  }
}

// ---- Data row (list item) --------------------------------------------

/// A consistent list-row tile for all entity list screens.
/// No ListTile — custom so we fully control the layout density.
class NexusDataRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? meta; // right-aligned small text (date, code, etc.)
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accentLeft; // if set, draws a 2px left border on hover

  const NexusDataRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.meta,
    this.badges = const [],
    this.trailing,
    this.onTap,
    this.accentLeft,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: NexusColors.overlay,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NexusSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: NexusColors.borderSubtle)),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: NexusTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (meta != null)
                        Text(meta!, style: NexusTypography.label),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: NexusTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(spacing: 4, children: badges),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

// ---- Avatar / initials -----------------------------------------------

class NexusAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const NexusAvatar({
    super.key,
    required this.name,
    this.color = NexusColors.primary,
    this.size = 36,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ---- Nexus screen scaffold -------------------------------------------

/// Standard page scaffold: consistent padding, optional action button.
class NexusScreen extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Color accentColor;
  final Widget? headerTrailing;
  final Widget? filterRow;
  final Widget body;
  final Widget? fab;

  const NexusScreen({
    super.key,
    required this.eyebrow,
    required this.title,
    this.accentColor = NexusColors.primary,
    this.headerTrailing,
    this.filterRow,
    required this.body,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.base,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header zone
          Container(
            padding: const EdgeInsets.fromLTRB(
              NexusSpacing.md,
              NexusSpacing.md,
              NexusSpacing.md,
              NexusSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: NexusColors.surface,
              border: Border(bottom: BorderSide(color: NexusColors.border)),
            ),
            child: NexusSectionHeader(
              eyebrow: eyebrow,
              title: title,
              accentColor: accentColor,
              trailing: headerTrailing,
            ),
          ),
          // Optional filter / search row
          if (filterRow != null)
            Container(
              padding: const EdgeInsets.fromLTRB(
                NexusSpacing.md,
                NexusSpacing.sm,
                NexusSpacing.md,
                NexusSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: NexusColors.surface,
                border: Border(
                  bottom: BorderSide(color: NexusColors.borderSubtle),
                ),
              ),
              child: filterRow!,
            ),
          // Main content area
          Expanded(child: body),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

// ---- Form bottom sheet wrapper ---------------------------------------

class NexusFormSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget form;

  const NexusFormSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NexusColors.surface,
        borderRadius: NexusRadius.sheet,
        border: Border(top: BorderSide(color: NexusColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        NexusSpacing.lg,
        NexusSpacing.md,
        NexusSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + NexusSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: NexusColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(title, style: NexusTypography.displayMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: NexusTypography.bodySmall),
          ],
          const SizedBox(height: NexusSpacing.lg),
          form,
        ],
      ),
    );
  }
}

// ---- Form helpers (Nexus-styled replacements for shared/form_helpers) -

Widget nexusTextField({
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
    padding: const EdgeInsets.only(bottom: NexusSpacing.md),
    child: TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: NexusTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
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

Widget nexusDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  bool required = false,
  void Function(T?)? onChanged,
  String? Function(T?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: NexusSpacing.md),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: NexusColors.surfaceHigh,
      style: NexusTypography.bodyMedium,
      decoration: InputDecoration(labelText: required ? '$label *' : label),
      items: items,
      onChanged: onChanged,
      validator:
          validator ??
          (required ? (v) => v == null ? '$label is required' : null : null),
    ),
  );
}

Widget nexusDateField({
  required BuildContext context,
  required String label,
  required DateTime? value,
  bool required = false,
  required void Function(DateTime) onPicked,
}) {
  final fmtDate = value == null
      ? null
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  return Padding(
    padding: const EdgeInsets.only(bottom: NexusSpacing.md),
    child: InkWell(
      borderRadius: NexusRadius.sm,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: NexusColors.primary,
                surface: NexusColors.surface,
                onSurface: NexusColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: NexusColors.textMuted,
          ),
        ),
        child: Text(
          fmtDate ?? 'Select date',
          style: NexusTypography.bodyMedium.copyWith(
            color: fmtDate != null
                ? NexusColors.textPrimary
                : NexusColors.textMuted,
          ),
        ),
      ),
    ),
  );
}

Widget nexusFormActions({
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
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(saveLabel),
      ),
    ],
  );
}
