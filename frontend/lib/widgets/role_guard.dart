import 'package:flutter/material.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final String currentRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.currentRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!allowedRoles.contains(currentRole)) return const SizedBox.shrink();
    return child;
  }
}
