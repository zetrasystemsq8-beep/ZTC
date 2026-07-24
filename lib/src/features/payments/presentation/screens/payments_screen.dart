import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_PaymentItem>[
      _PaymentItem(
        title: 'Send Money',
        subtitle: 'Transfer to any ZTC account',
        icon: Icons.send_rounded,
      ),
      _PaymentItem(
        title: 'Receive Money',
        subtitle: 'Share your account details',
        icon: Icons.call_received_rounded,
      ),
      _PaymentItem(
        title: 'Deposit',
        subtitle: 'Fund your wallet',
        icon: Icons.account_balance_wallet_rounded,
      ),
      _PaymentItem(
        title: 'Withdraw',
        subtitle: 'Move money to your bank',
        icon: Icons.account_balance_rounded,
      ),
      _PaymentItem(
        title: 'QR Payment',
        subtitle: 'Pay by scanning QR code',
        icon: Icons.qr_code_scanner_rounded,
      ),
      _PaymentItem(
        title: 'Airtime',
        subtitle: 'Recharge any network',
        icon: Icons.phone_android_rounded,
      ),
      _PaymentItem(
        title: 'Data',
        subtitle: 'Buy internet bundles',
        icon: Icons.wifi_rounded,
      ),
      _PaymentItem(
        title: 'Bills',
        subtitle: 'Electricity, TV & more',
        icon: Icons.receipt_long_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(item.icon),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
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

class _PaymentItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PaymentItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
