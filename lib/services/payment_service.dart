import 'package:tobias/tobias.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dream/services/api_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late Tobias _tobias;

  void initialize() {
    _tobias = Tobias();
  }

  /// 检查支付宝是否已安装
  Future<bool> isAlipayInstalled() async {
    try {
      return await _tobias.isAliPayInstalled;
    } catch (e, stackTrace) {
      print('=== 检查支付宝安装状态失败详细信息 ===');
      print('错误类型: ${e.runtimeType}');
      print('错误消息: $e');
      print('堆栈跟踪: $stackTrace');
      print('=====================================');
      return false;
    }
  }

  /// 发起支付宝支付
  Future<Map<String, dynamic>?> payWithAlipay({
    required int credits,
    required double amount,
  }) async {
    try {
      // 检查支付宝是否安装
      if (!await isAlipayInstalled()) {
        Fluttertoast.showToast(
          msg: '检测到您未安装支付宝',
          gravity: ToastGravity.CENTER,
        );
        return null;
      }

      // 创建支付订单
      final orderInfo = await _createPaymentOrder(credits, amount);
      if (orderInfo == null) {
        Fluttertoast.showToast(
          msg: '创建支付订单失败',
          gravity: ToastGravity.CENTER,
        );
        return null;
      }

      // 发起支付
      final result = await _tobias.pay(orderInfo);
      
      // 处理支付结果
      return await _handlePaymentResult(Map<String, dynamic>.from(result), credits);
    } catch (e, stackTrace) {
      print('=== 支付失败详细信息 ===');
      print('错误类型: ${e.runtimeType}');
      print('错误消息: $e');
      print('堆栈跟踪: $stackTrace');
      print('========================');
      
      String userMessage = '支付失败，请稍后重试';
      
      // 根据错误类型提供更友好的提示
      if (e.toString().contains('积分不足')) {
        userMessage = '积分不足，请先充值';
      } else if (e.toString().contains('网络')) {
        userMessage = '网络连接失败，请检查网络后重试';
      } else if (e.toString().contains('订单')) {
        userMessage = '订单创建失败，请重试';
      }
      
      Fluttertoast.showToast(
        msg: userMessage,
        gravity: ToastGravity.CENTER,
      );
      return null;
    }
  }

  /// 创建支付订单（这里需要调用后端API）
  Future<String?> _createPaymentOrder(int credits, double amount) async {
    try {
      // 调用后端API创建支付订单
      final response = await ApiService.dio.post(
        '/api/v1/payment/create-order',
        data: {
          'subject': '购买$credits积分',
          'body': '购买积分用于应用内消费',
          'total_amount': amount.toStringAsFixed(2),
          'out_trade_no': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200) {
        final paymentResponse = response.data;
        return paymentResponse['order_string'];
      } else {
        throw Exception('创建支付订单失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('=== 创建支付订单失败详细信息 ===');
      print('错误类型: ${e.runtimeType}');
      print('错误消息: $e');
      print('堆栈跟踪: $stackTrace');
      print('==============================');
      
      // 提供用户友好的错误提示
      String userMessage = '订单创建失败';
      if (e.toString().contains('401')) {
        userMessage = '登录已过期，请重新登录';
      } else if (e.toString().contains('403')) {
        userMessage = '权限不足';
      } else if (e.toString().contains('积分不足')) {
        userMessage = '积分不足';
      } else if (e.toString().contains('网络')) {
        userMessage = '网络连接失败';
      }
      
      Fluttertoast.showToast(
        msg: userMessage,
        gravity: ToastGravity.CENTER,
      );
      return null;
    }
  }

  /// 处理支付结果
  Future<Map<String, dynamic>?> _handlePaymentResult(
    Map<String, dynamic> result,
    int credits,
  ) async {
    try {
      final resultStatus = result['resultStatus'];
      final memo = result['memo'] ?? '';

      switch (resultStatus) {
        case '9000': // 支付成功
          Fluttertoast.showToast(
            msg: '支付成功！',
            gravity: ToastGravity.CENTER,
          );
          
          // 支付成功后，调用后端API添加积分
          await _addCreditsToUser(credits);
          
          return {
            'success': true,
            'message': '支付成功',
            'credits': credits,
          };
          
        case '8000': // 正在处理中
          Fluttertoast.showToast(
            msg: '支付结果确认中...',
            gravity: ToastGravity.CENTER,
          );
          return {
            'success': false,
            'message': '支付结果确认中',
          };
          
        case '4000': // 订单支付失败
          Fluttertoast.showToast(
            msg: '支付失败',
            gravity: ToastGravity.CENTER,
          );
          return {
            'success': false,
            'message': '支付失败',
          };
          
        case '5000': // 重复请求
          Fluttertoast.showToast(
            msg: '重复请求',
            gravity: ToastGravity.CENTER,
          );
          return {
            'success': false,
            'message': '重复请求',
          };
          
        case '6001': // 用户中途取消
          Fluttertoast.showToast(
            msg: '支付已取消',
            gravity: ToastGravity.CENTER,
          );
          return {
            'success': false,
            'message': '用户取消支付',
          };
          
        case '6002': // 网络连接出错
          Fluttertoast.showToast(
            msg: '网络连接出错',
            gravity: ToastGravity.CENTER,
          );
          return {
            'success': false,
            'message': '网络连接出错',
          };
          
        default:
          Fluttertoast.showToast(
            msg: '未知支付结果: $memo',
            gravity: ToastGravity.CENTER,
          );
          return {
            'success': false,
            'message': '未知支付结果: $memo',
          };
      }
    } catch (e, stackTrace) {
      print('=== 处理支付结果失败详细信息 ===');
      print('错误类型: ${e.runtimeType}');
      print('错误消息: $e');
      print('堆栈跟踪: $stackTrace');
      print('支付结果原始数据: $result');
      print('==============================');
      return {
        'success': false,
        'message': '支付结果处理失败',
      };
    }
  }

  /// 支付成功后添加积分到用户账户
  Future<void> _addCreditsToUser(int credits) async {
    // 服务器通过支付通知回调自动添加积分
    // 客户端无需直接调用添加积分API
    // 可以选择刷新用户积分余额
    print('支付成功，服务器将添加 $credits 积分');
    }

  /// 获取积分套餐列表
  List<Map<String, dynamic>> getCreditPackages() {
    return [
      {
        'credits': 10,
        'price': 1.00,
        'title': '10 积分',
        'subtitle': '¥ 1.00',
        'discount': '',
      },
      {
        'credits': 100,
        'price': 10.00,
        'title': '100 积分',
        'subtitle': '¥ 10.00',
        'discount': '',
      },
      {
        'credits': 550,
        'price': 50.00,
        'title': '550 积分',
        'subtitle': '¥ 50.00 (优惠 10%)',
        'discount': '10%',
      },
      {
        'credits': 1200,
        'price': 100.00,
        'title': '1200 积分',
        'subtitle': '¥ 100.00 (优惠 20%)',
        'discount': '20%',
      },
      {
        'credits': 6500,
        'price': 500.00,
        'title': '6500 积分',
        'subtitle': '¥ 500.00 (优惠 30%)',
        'discount': '30%',
      },
    ];
  }
}