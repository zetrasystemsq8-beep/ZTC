import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_AccountItem>[
      _AccountItem(
        title: 'Profile',
        subtitle: 'Manage your personal information',
        icon: Icons.person_rounded,
      ),
      _AccountItem(
        title: 'Security',
        subtitle: 'Password, PIN and biometric settings',
        icon: Icons.security_rounded,
      ),
      _AccountItem(
        title: 'Devices',
        subtitle: 'Manage connected devices',
        icon: Icons.devices_rounded,
      ),
      _AccountItem(
        title: 'Notifications',
        subtitle: 'Control your alerts and messages',
        icon: Icons.notifications_rounded,
      ),
      _AccountItem(
        title: 'Settings',
        subtitle: 'App preferences and customization',
        icon: Icons.settings_rounded,
      ),
      _AccountItem(
        title: 'Help & Support',
        subtitle: 'Get help with your ZTC account',
        icon: Icons.help_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 26,
                child: Icon(item.icon),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(item.subtitle),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.title} coming soon'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AccountItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AccountItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
