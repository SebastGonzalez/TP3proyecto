import 'package:flutter/material.dart';

/// AppBar estándar: solo flecha atrás cuando hay historial de navegación.
class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor;

    return AppBar(
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: fg,
      iconTheme: fg != null ? IconThemeData(color: fg) : null,
      title: Text(
        title,
        style: fg != null ? TextStyle(color: fg) : null,
      ),
      actions: actions,
    );
  }
}
