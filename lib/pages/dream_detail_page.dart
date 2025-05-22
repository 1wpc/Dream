import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dart:io';
import 'edit_dream_page.dart';
import 'package:flutter/services.dart';

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
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    setState(() {
      _scrollProgress = progress;
    });
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
          Navigator.pop(context, true); // 返回并通知列表页面刷新
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

  @override
  Widget build(BuildContext context) {
    // 设置状态栏为亮色内容
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDreamPage(dream: widget.dream),
                ),
              );
              if (result == true && mounted) {
                Navigator.pop(context, true); // 返回并通知列表页面刷新
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteDream,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Opacity(
              opacity: 1 - _scrollProgress,
              child: widget.dream.imageUrl != null
                  ? FutureBuilder<bool>(
                      future: File(widget.dream.imageUrl!).exists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (snapshot.hasError || !snapshot.data!) {
                          return Container(
                            color: Colors.blue.shade900,
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        }

                        return Image.file(
                          File(widget.dream.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.blue.shade900,
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Container(
                      color: Colors.blue.shade900,
                    ),
            ),
          ),
          // 渐变背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(_scrollProgress),
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),
          ),
          // 内容
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 标题区域
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,  // 调整高度
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dream.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(1 - _scrollProgress),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.dream.time,
                        style: TextStyle(
                          color: Colors.white.withOpacity(1 - _scrollProgress),
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 内容区域
              SliverFillRemaining(  // 使用SliverFillRemaining代替SliverToBoxAdapter
                hasScrollBody: false,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),  // 轻微透明度让背景若隐若现
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '梦境内容',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),  // 深蓝色标题
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.dream.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      const Spacer(),  // 用Spacer来填充底部剩余空间
                      // 添加一个底部区域，避免完全空白
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 16),
                          child: Text(
                            '记录于 ${_formatDate(widget.dream.time)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 格式化日期
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}年${date.month}月${date.day}日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
} 