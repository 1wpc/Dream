class PrivacyPolicyContent {
  // 隐私政策更新日期
  static const String lastUpdated = '2024年12月21日';
  
  // 隐私政策标题
  static const String title = '梦境记录隐私政策';
  
  // 隐私政策简介
  static const String introduction = '欢迎使用梦境记录应用！\n\n在开始使用之前，请仔细阅读我们的隐私政策。我们重视您的隐私，并承诺保护您的个人信息。';
  
  // 隐私政策各个章节
  static const List<PolicySection> sections = [
    PolicySection(
      title: '1. 信息收集',
      content: '我们收集以下类型的信息来为您提供更好的服务：\n\n'
          '• 账户信息：用户名、昵称、邮箱、手机号等注册信息\n'
          '• 梦境内容：您记录的梦境描述、图片和相关标签'
    ),
    PolicySection(
      title: '2. 信息使用',
      content: '我们使用收集的信息用于：\n\n'
          '• 提供梦境记录和分析服务\n'
          '• 改善应用功能和用户体验\n'
          '• 个性化用户体验\n'
          '• 数据分析和统计'
    ),
    PolicySection(
      title: '3. 信息分享',
      content: '我们承诺：\n\n'
          '• 不会向第三方出售您的个人信息\n'
          '• 在法律要求的情况下可能需要披露信息\n'
          '• 与服务提供商分享必要的技术数据以使用人工智能服务\n'
          '• 获得您的明确同意时才会分享信息'
    ),
    PolicySection(
      title: '4. 数据安全',
      content: '我们采取多重措施保护您的数据：\n\n'
          '• 使用加密技术传输和存储敏感信息\n'
          '• 定期进行安全审计和漏洞检测\n'
          '• 访问控制和权限管理\n'
          '• 员工隐私培训',
    ),
    PolicySection(
      title: '5. 用户权利',
      content: '您拥有以下权利：\n\n'
          '• 访问和查看您的个人信息\n'
          '• 修改或更新您的账户信息\n'
          '• 删除您的梦境记录和账户\n'
          '• 随时撤回对数据处理的同意\n'
          '• 数据可携带\n'
          '• 投诉和申诉',
    ),
    PolicySection(
      title: '6. 第三方服务',
      content: '我们的应用可能集成以下第三方服务：\n\n'
          '• AI分析服务：提供梦境解析功能\n'
          '• 支付服务：处理高级功能订阅\n\n'
          '这些服务有各自的隐私政策，我们建议您仔细阅读。我们不对第三方的隐私做法负责。',
    ),
    PolicySection(
      title: '7. 政策更新',
      content: '我们可能会不时更新本隐私政策：\n\n'
          '• 重大变更将通过应用通知您\n'
          '• 建议您定期查看本政策\n'
          '• 继续使用应用表示您接受更新后的政策',
    ),
  ];
  
  // 底部提示文本
  static const String bottomNotice = '继续使用表示您同意我们的隐私政策。如不同意，应用将退出。';
  
  // 获取所有章节内容的字符串
  static String getAllSectionsAsString() {
    return sections.map((section) => '${section.title}\n${section.content}').join('\n\n');
  }
  
  // 获取完整的隐私政策文本
  static String getFullPolicyText() {
    return '$introduction\n\n${getAllSectionsAsString()}\n\n$bottomNotice';
  }
}

// 隐私政策章节数据模型
class PolicySection {
  final String title;
  final String content;
  
  const PolicySection({
    required this.title,
    required this.content,
  });
}