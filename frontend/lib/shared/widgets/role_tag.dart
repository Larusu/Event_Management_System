import 'package:flutter/material.dart';

import '../../core/constants/roles.dart';

/// Human-readable label for a role string.
String roleLabel(String role) {
  switch (role) {
    case Roles.superAdmin:
      return 'Super Admin';
    case Roles.faculty:
      return 'Faculty';
    case Roles.organizer:
      return 'Organizer';
    case Roles.student:
      return 'Student';
    case Roles.guest:
      return 'Guest';
    default:
      return role.isEmpty ? 'Unknown' : role;
  }
}

/// Soft/tinted pill badge for a user role. One hue per role, reused wherever a
/// role is shown (role promotion list, profile/settings, etc.).
class RoleTag extends StatelessWidget {
  final String role;
  final double fontSize;

  const RoleTag({super.key, required this.role, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final colors = _RoleTagColors.forRole(role, context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        roleLabel(role),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class _RoleTagColors {
  final Color background;
  final Color foreground;

  const _RoleTagColors(this.background, this.foreground);

  static _RoleTagColors forRole(String role, BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    switch (role) {
      case Roles.superAdmin:
        return _RoleTagColors(
          isDark
              ? Colors.deepPurple.shade800.withValues(alpha: 0.4)
              : Colors.deepPurple.shade50,
          isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700,
        );
      case Roles.faculty:
        return _RoleTagColors(
          isDark
              ? Colors.indigo.shade800.withValues(alpha: 0.4)
              : Colors.indigo.shade50,
          isDark ? Colors.indigo.shade200 : Colors.indigo.shade700,
        );
      case Roles.organizer:
        return _RoleTagColors(
          isDark
              ? Colors.teal.shade800.withValues(alpha: 0.4)
              : Colors.teal.shade50,
          isDark ? Colors.teal.shade200 : Colors.teal.shade700,
        );
      case Roles.student:
        return _RoleTagColors(
          isDark
              ? Colors.orange.shade800.withValues(alpha: 0.4)
              : Colors.orange.shade50,
          isDark ? Colors.orange.shade200 : Colors.orange.shade800,
        );
      case Roles.guest:
        return _RoleTagColors(
          isDark
              ? Colors.blueGrey.shade800.withValues(alpha: 0.4)
              : Colors.blueGrey.shade50,
          isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
        );
      default:
        return _RoleTagColors(
          isDark
              ? Colors.grey.shade800.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        );
    }
  }
}
