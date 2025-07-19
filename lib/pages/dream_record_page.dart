import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'add_dream_page.dart';
import 'dream_detail_page.dart';
import 'dart:io';

class DreamRecordPage extends StatefulWidget {
  const DreamRecordPage({super.key});

  @override
  State<DreamRecordPage> createState() => _DreamRecordPageState();
}

class _DreamRecordPageState extends State<DreamRecordPage> 
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<DreamRecord> _dreams = [];
  List<DreamRecord> _filteredDreams = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadDreams();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDreams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dreams = await _databaseService.getAllDreams();
      setState(() {
        _dreams = dreams;
        _filteredDreams = dreams;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  void _searchDreams(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDreams = _dreams;
      } else {
        _filteredDreams = _dreams.where((dream) {
          return dream.title.toLowerCase().contains(query.toLowerCase()) ||
                 dream.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        _filteredDreams = _dreams;
      } else {
        _isSearching = true;
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchDreams,
        decoration: InputDecoration(
          hintText: '搜索梦境标题或内容...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade600,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchDreams('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Future<void> _deleteDream(int id) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
        await _databaseService.deleteDream(id);
        await _loadDreams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除成功 ✨'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '今天 ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays == 1) {
        return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return DateFormat('MM月dd日').format(dateTime);
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildDreamCard(DreamRecord dream, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            1.0,
            curve: Curves.easeOutCubic,
          ),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DreamDetailPage(
                          dream: dream,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadDreams();
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 头部区域 - 图片或渐变背景
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: dream.imageUrl != null && File(dream.imageUrl!).existsSync()
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.purple.shade400,
                                    Colors.pink.shade300,
                                  ],
                                ),
                        ),
                        child: dream.imageUrl != null && File(dream.imageUrl!).existsSync()
                            ? Image.file(
                                File(dream.imageUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultBackground();
                                },
                              )
                            : _buildDefaultBackground(),
                      ),
                      // 内容区域
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题和时间
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dream.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A237E),
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateTime(dream.time),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // 操作按钮
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.red.shade400,
                                        ),
                                        onPressed: () => _deleteDream(dream.id!),
                                        tooltip: '删除',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.blue.shade600,
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DreamDetailPage(
                                                dream: dream,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadDreams();
                                          }
                                        },
                                        tooltip: '查看详情',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 内容预览
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Text(
                                dream.content,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
            Colors.pink.shade300,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nights_stay,
              color: Colors.white.withOpacity(0.8),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              '梦境',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '我的梦境',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_dreams.isNotEmpty)
            IconButton(
              icon: Icon(
                _isSearching ? Icons.search_off : Icons.search,
                color: Colors.white,
              ),
              onPressed: _toggleSearch,
              tooltip: _isSearching ? '关闭搜索' : '搜索梦境',
            ),
          if (_dreams.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '共 ${_dreams.length} 个梦境',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (_isSearching && _filteredDreams.length != _dreams.length)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '找到 ${_filteredDreams.length} 个结果',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在加载梦境记录...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _dreams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nights_stay_outlined,
                          color: Colors.white.withOpacity(0.6),
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '还没有梦境记录',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '点击右下角按钮开始记录你的第一个梦境',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadDreams,
                        child: _filteredDreams.isEmpty && _isSearching
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 80,
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      '没有找到匹配的梦境',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '尝试使用其他关键词搜索',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  _isSearching ? 180 : 120,
                                  16,
                                  100,
                                ),
                                itemCount: _filteredDreams.length,
                                itemBuilder: (context, index) {
                                  return _buildDreamCard(_filteredDreams[index], index);
                                },
                              ),
                      ),
                      if (_isSearching) _buildSearchBar(),
                    ],
                  ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddDreamPage()),
            );
            if (result == true) {
              _loadDreams();
            }
          },
          backgroundColor: Colors.white,
          foregroundColor: Colors.purple.shade600,
          elevation: 0,
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            '记录梦境',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}