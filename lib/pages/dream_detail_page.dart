import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dart:io';
import 'edit_dream_page.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class DreamDetailPage extends StatefulWidget {
  final DreamRecord dream;

  const DreamDetailPage({
    super.key,
    required this.dream,
  });

  @override
  State<DreamDetailPage> createState() => _DreamDetailPageState();
}

class _DreamDetailPageState extends State<DreamDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // 减少setState的调用频率，只在变化超过一定阈值时更新
    double newProgress;
    if (currentScroll <= 0) {
      newProgress = (currentScroll / 300).clamp(-1.0, 0.0); // 增加下拉距离
    } else {
      newProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    }
    
    // 只在变化超过0.01时才更新，减少重建
    if ((newProgress - _scrollProgress).abs() > 0.01) {
      setState(() {
        _scrollProgress = newProgress;
      });
    }
  }

  Future<void> _deleteDream() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条梦境记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteDream(widget.dream.id!);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }

  Widget _buildBackgroundImage() {
    return widget.dream.imageUrl != null
        ? FutureBuilder<bool>(
            future: File(widget.dream.imageUrl!).exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade900,
                        Colors.purple.shade900,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              
              if (snapshot.hasError || !snapshot.data!) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade900,
                        Colors.purple.shade900,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.nights_stay,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              }

              return Image.file(
                File(widget.dream.imageUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade900,
                          Colors.purple.shade900,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.nights_stay,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  );
                },
              );
            },
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900,
                  Colors.purple.shade900,
                ],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.6;
    
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 使用SliverAppBar实现真正的下拉效果
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            stretch: true, // 允许拉伸
            onStretchTrigger: () async {
              // 可以在这里添加下拉触发的逻辑
              HapticFeedback.lightImpact();
            },
            backgroundColor: _scrollProgress > 0.5 
                ? Colors.white.withOpacity(0.9) 
                : Colors.transparent,
            elevation: _scrollProgress > 0.5 ? 4 : 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: _scrollProgress > 0.5 ? Colors.black : Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: _scrollProgress > 0.5 ? Colors.black : Colors.white,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDreamPage(dream: widget.dream),
                    ),
                  );
                  if (result == true && mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: _scrollProgress > 0.5 ? Colors.black : Colors.white,
                ),
                onPressed: _deleteDream,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图片
                  _buildBackgroundImage(),
                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // 标题信息
                  Positioned(
                    bottom: 60,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.dream.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(widget.dream.time),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
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
            ),
          ),
          // 内容区域
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部拖拽指示器
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.nights_stay,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '梦境内容',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.dream.content,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // 底部装饰区域
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '愿美梦成真',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
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
  
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}年${date.month}月${date.day}日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
} 