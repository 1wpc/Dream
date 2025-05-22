import 'package:flutter/material.dart';
import 'daydream_page.dart';
import 'dream_record_page.dart';
import 'zhougong_dream_page.dart';

class DreamCorePage extends StatelessWidget {
  const DreamCorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 全景背景
          Positioned.fill(
            child: Image.asset(
              'assets/images/dream_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 半透明遮罩
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
          // 功能模块
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '梦核',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _buildFeatureCard(
                          context,
                          '白日梦',
                          Icons.cloud,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DaydreamPage(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          '记录梦',
                          Icons.book,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DreamRecordPage(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          '周公解梦',
                          Icons.psychology,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ZhougongDreamPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 