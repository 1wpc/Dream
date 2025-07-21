import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/auth_service.dart';
import '../services/points_service.dart';
import '../services/database_service.dart';
import 'login_page.dart';
import 'privacy_policy_page.dart';
import 'purchase_credits_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  PointsBalance? _pointsBalance;
  bool _isLoadingPoints = false;
  late PointsService _pointsService;
  int dreamCount = 0;
  bool isLoadingDreams = false;

  @override
  void initState() {
    super.initState();
    // 初始化时刷新用户信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _pointsService = PointsService();
      if (authService.isLoggedIn) {
        _loadPointsBalance();
        _loadDreamCount();
      }
    });
  }

  /// 加载积分余额
  Future<void> _loadPointsBalance() async {
    if (_isLoadingPoints) return;
    
    setState(() {
      _isLoadingPoints = true;
    });

    try {
      final pointsBalance = await _pointsService.getPointsBalance();
      if (mounted) {
        setState(() {
          _pointsBalance = pointsBalance;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
      print('加载积分余额失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });
      }
    }
  }

  Future<void> _loadDreamCount() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingDreams = true;
    });

    try {
      final databaseService = DatabaseService();
      final dreams = await databaseService.getAllDreams();
      
      if (mounted) {
        setState(() {
          dreamCount = dreams.length;
          isLoadingDreams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDreams = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载梦境数量失败: $e')),
        );
      }
    }
  }

  /// 显示积分详情对话框
  Future<void> _showPointsDetailDialog() async {
    // 如果还没有加载积分数据，先加载
    if (_pointsBalance == null && !_isLoadingPoints) {
      await _loadPointsBalance();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('积分详情'),
            ],
          ),
          content: _pointsBalance == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingPoints) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('正在加载积分信息...'),
                    ] else ... [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('暂无积分信息'),
                    ],
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('当前余额', _pointsBalance!.pointsBalance, Colors.orange),
                    const SizedBox(height: 12),
                    _buildDetailRow('总获得积分', _pointsBalance!.totalPointsEarned, Colors.green),
                    const SizedBox(height: 12),
                    _buildDetailRow('总消费积分', _pointsBalance!.totalPointsSpent, Colors.red),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '点击积分卡片可刷新最新数据',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            if (_pointsBalance != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadPointsBalance(); // 刷新数据
                },
                child: const Text('刷新'),
              ),
          ],
        );
      },
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 导航到编辑个人信息页面
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
    
    // 如果编辑成功，刷新页面
    if (result == true) {
      setState(() {});
    }
  }

  // 显示登出确认对话框
  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF374151),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (!authService.isLoggedIn) {
            return _buildNotLoggedIn();
          }
          
          if (authService.isLoading) {
            return _buildLoading();
          }
          
          return _buildProfileContent(authService);
        },
      ),
    );
  }

  // 未登录状态
  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '您还未登录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed)) {
                    return const Color(0xFF5a67d8);
                  }
                  return const Color(0xFF667eea);
                },
              ),
            ),
            child: const Text(
              '立即登录',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // 加载状态
  Widget _buildLoading() {
    return const Center(
      child: SpinKitCircle(
        color: Color(0xFF667eea),
        size: 50,
      ),
    );
  }

  // 个人信息内容
  Widget _buildProfileContent(AuthService authService) {
    final user = authService.userProfile;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 用户信息卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFFf093fb),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // 头像
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: user?.avatar != null && user!.avatar.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            user.avatar,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
                
                const SizedBox(height: 16),
                
                // 昵称
                Text(
                  user?.nickname ?? '未知用户',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 个人简介
                Text(
                  user?.bio ?? '这个人很神秘，什么都没有留下...',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // 编辑按钮
                ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑资料'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 统计信息
          Row(
            children: [
              Expanded(
                child: _buildPointsCard(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '梦境',
                  '$dreamCount',
                  Icons.nights_stay,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 功能菜单
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    final apiUser = authService.currentApiUser;
                    final pointsBalance = apiUser?.pointsBalance ?? '0';
                    final totalEarned = apiUser?.totalPointsEarned ?? '0';
                    
                    return _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: '积分详情',
                      subtitle: apiUser != null 
                        ? '余额: $pointsBalance | 总获得: $totalEarned'
                        : '点击查看详细积分信息',
                      onTap: () {
                        _showPointsDetailDialog();
                      },
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                 _buildMenuItem(
                  icon: Icons.shopping_cart_checkout_rounded,
                  title: '购买积分',
                  onTap: () {
                     Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PurchaseCreditsPage()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: '查看隐私协议',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 退出登录按钮
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: _buildMenuItem(
              icon: Icons.logout,
              title: '退出登录',
              onTap: _showLogoutDialog,
              showDivider: false,
            ),
          )
        ],
      ),
    );
  }

  // 默认头像
  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 40,
      color: Color(0xFF667eea),
    );
  }

  // 积分卡片（带刷新功能）
  Widget _buildPointsCard() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final apiUser = authService.currentApiUser;
        final pointsBalance = apiUser?.pointsBalance ?? '0';
        
        return GestureDetector(
          onTap: () async {
            // 刷新用户信息以获取最新积分
            try {
              await authService.refreshUserInfo();
            } catch (e) {
              print('刷新用户信息失败: $e');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 24,
                      color: Colors.orange,
                    ),
                    if (authService.isLoading)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pointsBalance,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '积分',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 统计卡片
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 构建菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}