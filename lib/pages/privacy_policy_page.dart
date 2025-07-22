import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '隐私政策',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1C2E),
              Color(0xFF2D3561),
              Color(0xFF1A1C2E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '梦境记录隐私政策',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '最后更新日期：2024年12月21日',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 政策内容
              _buildPolicySection(
                '1. 信息收集',
                '我们收集以下类型的信息来为您提供更好的服务：\n\n'
                '• 账户信息：用户名、昵称、邮箱等注册信息\n'
                '• 梦境内容：您记录的梦境描述、图片和相关标签\n'
              ),

              _buildPolicySection(
                '2. 信息使用',
                '我们使用收集的信息用于：\n\n'
                '• 提供梦境记录和分析服务\n'
                '• 改善应用功能和用户体验\n'
              ),

              _buildPolicySection(
                '3. 信息分享',
                '我们承诺：\n\n'
                '• 不会向第三方出售您的个人信息\n'
                '• 在法律要求的情况下可能需要披露信息\n'
                '• 与服务提供商分享必要的技术数据以使用人工智能服务',
              ),

              _buildPolicySection(
                '4. 数据安全',
                '我们采取多重措施保护您的数据：\n\n'
                '• 使用加密技术传输和存储敏感信息\n'
                '• 定期进行安全审计和漏洞检测\n'
                '• 限制员工对用户数据的访问权限\n'
                '• 建立数据备份和恢复机制',
              ),

              _buildPolicySection(
                '5. 用户权利',
                '您拥有以下权利：\n\n'
                '• 访问和查看您的个人信息\n'
                '• 修改或更新您的账户信息\n'
                '• 删除您的梦境记录和账户\n'
                '• 选择性地控制数据分享设置\n'
                '• 随时撤回对数据处理的同意',
              ),

              _buildPolicySection(
                '6. 第三方服务',
                '我们的应用可能集成以下第三方服务：\n\n'
                '• AI分析服务：提供梦境解析功能\n'
                '• 支付服务：处理高级功能订阅\n\n'
                '这些服务有各自的隐私政策，我们建议您仔细阅读。',
              ),

              _buildPolicySection(
                '7. 政策更新',
                '我们可能会不时更新本隐私政策：\n\n'
                '• 重大变更将通过应用通知您\n'
                '• 建议您定期查看本政策\n'
                '• 继续使用应用表示您接受更新后的政策',
              ),

              const SizedBox(height: 40),

              // 底部同意按钮
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B73FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '我已阅读并理解隐私政策',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
} 