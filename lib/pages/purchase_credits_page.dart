import 'package:flutter/material.dart';

class PurchaseCreditsPage extends StatelessWidget {
  const PurchaseCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('购买积分'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900.withOpacity(0.8),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCreditOption(context, '100 积分', '¥ 10.00'),
              const SizedBox(height: 16),
              _buildCreditOption(context, '550 积分', '¥ 50.00 (优惠 10%)'),
              const SizedBox(height: 16),
              _buildCreditOption(context, '1200 积分', '¥ 100.00 (优惠 20%)'),
              const SizedBox(height: 16),
              _buildCreditOption(context, '6500 积分', '¥ 500.00 (优惠 30%)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditOption(BuildContext context, String title, String price) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          price,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // 购买逻辑
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已选择 $title')),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text('购买'),
        ),
      ),
    );
  }
} 