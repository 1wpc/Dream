import 'api_service.dart';

class PointsBalance {
  final String pointsBalance;
  final String totalPointsEarned;
  final String totalPointsSpent;

  PointsBalance({
    required this.pointsBalance,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
  });

  factory PointsBalance.fromJson(Map<String, dynamic> json) {
    return PointsBalance(
      pointsBalance: json['points_balance'] ?? '0',
      totalPointsEarned: json['total_points_earned'] ?? '0',
      totalPointsSpent: json['total_points_spent'] ?? '0',
    );
  }

  int get pointsBalanceInt => int.tryParse(pointsBalance) ?? 0;
  int get totalPointsEarnedInt => int.tryParse(totalPointsEarned) ?? 0;
  int get totalPointsSpentInt => int.tryParse(totalPointsSpent) ?? 0;
}

class PointsService {
  PointsService();

  /// 获取当前用户积分余额
  Future<PointsBalance?> getPointsBalance() async {
    try {
      // 检查用户是否登录
      final token = await ApiService.getToken();
      if (token == null) {
        print('用户未登录，无法获取积分余额');
        return null;
      }

      // 使用ApiService的dio实例发送请求
      final response = await ApiService.dio.get('/api/v1/points/balance');

      print('积分余额API响应状态码: ${response.statusCode}');
      print('积分余额API响应内容: ${response.data}');

      if (response.statusCode == 200) {
        return PointsBalance.fromJson(response.data);
      } else if (response.statusCode == 404) {
        print('用户积分记录不存在');
        // 返回默认的积分余额
        return PointsBalance(
          pointsBalance: '0',
          totalPointsEarned: '0',
          totalPointsSpent: '0',
        );
      } else {
        print('获取积分余额失败: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      print('获取积分余额异常: $e');
      return null;
    }
  }
}