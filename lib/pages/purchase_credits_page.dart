import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class PurchaseCreditsPage extends StatefulWidget {
  const PurchaseCreditsPage({super.key});

  @override
  State<PurchaseCreditsPage> createState() => _PurchaseCreditsPageState();
}

class _PurchaseCreditsPageState extends State<PurchaseCreditsPage> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final creditPackages = _paymentService.getCreditPackages();
    
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.paymentProcessing,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectCreditsPackage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: creditPackages.length,
                        itemBuilder: (context, index) {
                          final package = creditPackages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildCreditOption(
                              context,
                              package['title'],
                              package['subtitle'],
                              package['credits'],
                              package['price'],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCreditOption(
    BuildContext context,
    String title,
    String subtitle,
    int credits,
    double price,
  ) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handlePurchase(credits, price),
              icon: const Icon(Icons.payment, size: 20),
              label: const Text('支付宝支付'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade600,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理购买逻辑
  Future<void> _handlePurchase(int credits, double price) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _paymentService.payWithAlipay(
        credits: credits,
        amount: price,
      );

      if (result != null && result['success'] == true) {
        // 支付成功
        if (mounted) {
          // 刷新用户信息以更新积分
          final authService = Provider.of<AuthService>(context, listen: false);
          try {
            // 从服务器重新获取用户信息以更新积分
            await authService.refreshUserInfo();
          } catch (e) {
            print('刷新用户信息失败: $e');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.paymentSuccessCredits(result['credits'].toString())),
              backgroundColor: Colors.green,
            ),
          );
          
          // 可以在这里刷新用户积分余额或返回上一页
          Navigator.of(context).pop(true); // 返回true表示支付成功
        }
      } else {
        // 支付失败或取消
        if (mounted && result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? AppLocalizations.of(context)!.paymentFailedMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('=== 购买积分页面支付错误详细信息 ===');
      print('错误类型: ${e.runtimeType}');
      print('错误消息: $e');
      print('堆栈跟踪: $stackTrace');
      print('积分数量: $credits');
      print('支付金额: $price');
      print('===================================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.paymentErrorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}