import 'package:flutter/material.dart';

class DreamStyleSelectionPage extends StatelessWidget {
  const DreamStyleSelectionPage({super.key});

  // 梦境风格定义
  static final List<DreamStyle> dreamStyles = [
    DreamStyle(
      id: 'fantasy',
      name: '奇幻梦境',
      description: '魔法森林、古堡与神秘生物',
      icon: Icons.auto_awesome,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      keywords: 'fantasy, magical, mystical, enchanted forest, castle, fairy tale',
    ),
    DreamStyle(
      id: 'nature',
      name: '自然梦境',
      description: '山川湖海、花草与星辰',
      icon: Icons.nature,
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      keywords: 'nature, landscape, mountains, ocean, forest, sunset, peaceful',
    ),
    DreamStyle(
      id: 'cyberpunk',
      name: '赛博朋克',
      description: '霓虹灯光与未来科技',
      icon: Icons.computer,
      gradient: [Color(0xFF833ab4), Color(0xFFfd1d1d), Color(0xFFfcb045)],
      keywords: 'cyberpunk, neon lights, futuristic, technology, city, sci-fi',
    ),
    DreamStyle(
      id: 'vintage',
      name: '复古怀旧',
      description: '温暖时光与老式建筑',
      icon: Icons.camera_alt,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      keywords: 'vintage, retro, nostalgic, warm colors, old buildings, classic',
    ),
    DreamStyle(
      id: 'minimalist',
      name: '简约禅意',
      description: '留白美学与静谧空间',
      icon: Icons.spa,
      gradient: [Color(0xFFffecd2), Color(0xFFfcb69f)],
      keywords: 'minimalist, zen, clean, simple, peaceful, meditation, calm',
    ),
    DreamStyle(
      id: 'surreal',
      name: '超现实',
      description: '奇异组合与梦幻变形',
      icon: Icons.blur_on,
      gradient: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
      keywords: 'surreal, abstract, impossible, dream-like, artistic, creative',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C3E50),
                  Color(0xFF34495E),
                  Color(0xFF2C3E50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部标题栏
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Text(
                            '选择梦境风格',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.only(left: 48),
                        child: Text(
                          '选择一种梦境风格，AI将为您编织独特的梦境体验',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 风格选择网格
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: dreamStyles.length,
                      itemBuilder: (context, index) {
                        final style = dreamStyles[index];
                        return _buildStyleCard(context, style);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(BuildContext context, DreamStyle style) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // 添加选择反馈
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择：${style.name}'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: style.gradient.first,
            ),
          );
          
          // 延迟返回选择的风格
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pop(context, style);
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: style.gradient.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  style.icon,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  style.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    style.description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 梦境风格数据模型
class DreamStyle {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String keywords;

  DreamStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.keywords,
  });
}