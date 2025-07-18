import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dream_style_selection_page.dart';
import 'dream_record_page.dart';
import 'zhougong_dream_page.dart';
import 'meditation_page.dart';

import 'dart:math' as math;

class DreamCorePage extends StatefulWidget {
  const DreamCorePage({super.key});

  @override
  State<DreamCorePage> createState() => _DreamCorePageState();
}

class _DreamCorePageState extends State<DreamCorePage> 
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _cardController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _cardAnimation;

  final List<FeatureItem> _features = [
    FeatureItem(
      title: '白日梦',
      subtitle: 'AI编织梦境',
      icon: Icons.auto_awesome,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      page: () => const DreamStyleSelectionPage(),
    ),
    FeatureItem(
      title: '记录梦',
      subtitle: '珍藏美梦',
      icon: Icons.nights_stay,
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      page: () => const DreamRecordPage(),
    ),
    FeatureItem(
      title: '周公解梦',
      subtitle: '探索梦境奥秘',
      icon: Icons.psychology,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
      page: () => const ZhougongDreamPage(),
    ),
    FeatureItem(
      title: '冥想',
      subtitle: '静心养神',
      icon: Icons.self_improvement,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      page: () => const MeditationPage(),
    ),

  ];

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.linear,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));
    
    _floatingController.repeat();
    _cardController.forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    return Scaffold(
      body: Stack(
        children: [
          // 梦幻星空背景
          _buildDreamBackground(),
          
          // 浮动粒子效果
          _buildFloatingParticles(),
          
          // 主要内容
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题区域
                  _buildHeader(),
                  
                  const SizedBox(height: 50),
                  
                  // 功能卡片网格
                  Expanded(
                    child: _buildFeatureGrid(),
                  ),
                  
                  // 底部装饰
                  _buildBottomDecoration(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamBackground() {
    return Positioned.fill(
        child: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
              Color(0xFF1a1c2e), // 深紫蓝
              Color(0xFF2d1b69), // 深紫
              Color(0xFF11001a), // 深黑紫
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 星光效果
            ...List.generate(50, (index) {
              return Positioned(
                left: math.Random().nextDouble() * 400,
                top: math.Random().nextDouble() * 800,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.5 + 0.5 * math.sin(_floatingAnimation.value + index * 0.5),
                      child: Container(
                        width: 2,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final offset = _floatingAnimation.value + index * 0.8;
            return Positioned(
              left: 100 + 80 * math.sin(offset),
              top: 200 + 60 * math.cos(offset * 0.8) + index * 80,
              child: Transform.scale(
                scale: 0.3 + 0.2 * math.sin(offset * 2),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '梦核',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Dream Core',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '探索梦境的无限可能',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final delay = index * 0.1;
            final animation = Tween<double>(
              begin: 0,
              end: 1,
            ).animate(CurvedAnimation(
              parent: _cardController,
              curve: Interval(delay, 1.0, curve: Curves.elasticOut),
            ));
            
            return Transform.scale(
              scale: animation.value,
              child: _buildFeatureCard(_features[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(FeatureItem feature, int index) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => feature.page(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: feature.gradient.map((c) => c.withOpacity(0.8)).toList(),
          ),
          boxShadow: [
            BoxShadow(
              color: feature.gradient.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      feature.icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
              Text(
                    feature.title,
                style: const TextStyle(
                      fontSize: 18,
                  fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomDecoration() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white.withOpacity(0.4),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '愿美梦成真',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.auto_awesome,
            color: Colors.white.withOpacity(0.4),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Widget Function() page;

  FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.page,
  });
}