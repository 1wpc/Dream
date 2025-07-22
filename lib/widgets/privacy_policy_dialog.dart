import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/privacy_service.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDisagree;
  
  const PrivacyPolicyDialog({
    Key? key,
    required this.onAgree,
    required this.onDisagree,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁止返回键关闭弹窗
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1C2E),
                Color(0xFF2D3561),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题部分
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '隐私政策',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 内容部分
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '欢迎使用梦境记录应用！',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '更新日期：2024年1月1日',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '在开始使用之前，请仔细阅读我们的隐私政策。我们重视您的隐私，并承诺保护您的个人信息。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPolicyPoint(
                        '1. 信息收集',
                        '我们可能收集以下类型的信息：\n'
                        '• 账户信息：用户名、邮箱地址等注册信息\n'
                        '• 梦境记录：您主动输入的梦境内容和相关数据\n'
                        '• 使用数据：应用使用统计、功能偏好等\n'
                        '• 设备信息：设备型号、操作系统版本等技术信息',
                      ),
                      _buildPolicyPoint(
                        '2. 信息使用',
                        '我们使用收集的信息用于：\n'
                        '• 提供和改进应用服务\n'
                        '• 个性化用户体验\n'
                        '• 数据分析和统计\n'
                        '• 技术支持和客户服务\n'
                        '• 安全防护和欺诈预防',
                      ),
                      _buildPolicyPoint(
                        '3. 信息分享',
                        '我们不会向第三方出售、交易或转让您的个人信息，除非：\n'
                        '• 获得您的明确同意\n'
                        '• 法律法规要求\n'
                        '• 保护我们的权利和安全\n'
                        '• 与可信的服务提供商合作（在严格的保密协议下）',
                      ),
                      _buildPolicyPoint(
                        '4. 数据安全',
                        '我们采取多种安全措施保护您的信息：\n'
                        '• 数据加密传输和存储\n'
                        '• 访问控制和权限管理\n'
                        '• 定期安全审计\n'
                        '• 员工隐私培训',
                      ),
                      _buildPolicyPoint(
                        '5. 用户权利',
                        '您有权：\n'
                        '• 访问和更新您的个人信息\n'
                        '• 删除您的账户和数据\n'
                        '• 撤回同意\n'
                        '• 数据可携带\n'
                        '• 投诉和申诉',
                      ),
                      _buildPolicyPoint(
                        '6. 第三方服务',
                        '我们的应用可能包含第三方服务的链接。这些第三方有自己的隐私政策，我们不对其隐私做法负责。建议您仔细阅读第三方的隐私政策。',
                      ),
                      _buildPolicyPoint(
                        '7. 政策更新',
                        '我们可能会不时更新本隐私政策。重大变更时，我们会通过应用内通知或其他方式告知您。继续使用应用即表示您接受更新后的政策。',
                      ),
                      _buildPolicyPoint(
                        '8. 联系我们',
                        '如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：\n'
                        '• 邮箱：privacy@dreamrecorder.com\n'
                        '• 地址：中国北京市朝阳区xxx街道xxx号',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '继续使用表示您同意我们的隐私政策。如不同意，应用将退出。',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 按钮部分
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDisagree,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '不同意',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          await PrivacyService.setPrivacyPolicyAgreed();
                          onAgree();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B73FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '同意并继续',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPolicyPoint(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}