import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/core/menu/menu_item.dart';
import 'package:prueba1/core/services/auth_service.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/drawer_navigation_provider.dart';
import 'package:prueba1/presentation/widgets/default_user_avatar.dart';

/// Menú lateral de la app: perfil + secciones + cerrar sesión.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static void navigate(BuildContext context, WidgetRef ref, String route) {
    final current = GoRouterState.of(context).uri.path;
    Navigator.pop(context);

    if (route == '/home') {
      if (current != '/home') {
        context.go('/home');
      }
      ref.read(reopenDrawerOnHomeProvider.notifier).state = true;
      return;
    }

    if (current == route) return;

    ref.read(reopenDrawerOnHomeProvider.notifier).state = true;
    context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(currentUsernameProvider);

    return SafeArea(
      child: NavigationDrawer(
        header: _DrawerProfileHeader(
          username: username,
          onProfileTap: () => navigate(context, ref, '/profile'),
        ),
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton.icon(
            onPressed: () async {
              clearLoggedInUsername(ref);
              await AuthService.logout();
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
        children: [
          for (var i = 0; i < appMenuSections.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            _DrawerSection(
              section: appMenuSections[i],
              onItemTap: (route) => navigate(context, ref, route),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader({
    required this.username,
    required this.onProfileTap,
  });

  final String username;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: InkWell(
        onTap: onProfileTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DefaultUserAvatar(radius: 36),
            const Spacer(),
            Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ver perfil',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.section,
    required this.onItemTap,
  });

  final MenuSection section;
  final void Function(String route) onItemTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.outline,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(section.label, style: labelStyle),
        ),
        for (final item in section.items)
          _DrawerMenuTile(
            item: item,
            onTap: () => onItemTap(item.route),
          ),
      ],
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.item,
    required this.onTap,
  });

  final MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(item.icon, color: colorScheme.primary),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
