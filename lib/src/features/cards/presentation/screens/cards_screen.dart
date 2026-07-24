import 'package:flutter/material.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_CardFeature>[
      _CardFeature(
        title: 'Virtual Card',
        subtitle: 'Create and manage your ZTC virtual card',
        icon: Icons.credit_card_rounded,
      ),
      _CardFeature(
        title: 'Physical Card',
        subtitle: 'Order your ZTC physical card',
        icon: Icons.card_membership_rounded,
      ),
      _CardFeature(
        title: 'Rewards',
        subtitle: 'Earn rewards from using ZTC',
        icon: Icons.card_giftcard_rounded,
      ),
      _CardFeature(
        title: 'Coins',
        subtitle: 'Manage your ZTC reward coins',
        icon: Icons.monetization_on_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards & Rewards'),
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

class _CardFeature {
  final String title;
  final String subtitle;
  final IconData icon;

  const _CardFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
