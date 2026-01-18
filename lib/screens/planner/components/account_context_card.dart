import 'package:flutter/material.dart';

class AccountContextCard extends StatelessWidget {
  const AccountContextCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Account Context",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Account Size: —"),
            Text("Buying Power: —"),
            Text("Shares Owned: —"),
          ],
        ),
      ),
    );
  }
}