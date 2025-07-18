import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/dream_api_service.dart';
import '../models/dream_models.dart';

class DreamForumPage extends StatefulWidget {
  const DreamForumPage({super.key});

  @override
  State<DreamForumPage> createState() => _DreamForumPageState();
}

class _DreamForumPageState extends State<DreamForumPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  
  final List<String> _categories = [
    '全部', '奇幻', '自然', '赛博朋克', '复古', '禅意', '超现实', '治愈', '冒险'
  ];
  
  List<DreamPost> _dreamPosts = [];
  List<DreamPost> _searchResults = [];

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _scrollController = ScrollController();
    _floatingController.repeat();
    
    // 初始化时加载数据
    _loadDreams();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 加载梦境数据
  Future<void> _loadDreams() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final category = _selectedCategoryIndex == 0 ? null : _categories[_selectedCategoryIndex];
      final dreams = await DreamApiService.getDreams(category: category);
      
      // 再次确保数据按发布时间降序排列
      dreams.sort((a, b) => b.publishTime.compareTo(a.publishTime));
      
      setState(() {
        _dreamPosts = dreams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('加载梦境失败: $e');
    }
  }

  // 刷新数据
  Future<void> _refreshDreams() async {
    await _loadDreams();
  }

  // 搜索梦境
  Future<void> _searchDreams(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });

      final results = await DreamApiService.searchDreams(query);
      
      // 确保搜索结果也按发布时间降序排列
      results.sort((a, b) => b.publishTime.compareTo(a.publishTime));
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = e.toString();
      });
      print('搜索失败: $e');
    }
  }

  // 点赞梦境
  Future<void> _likeDream(String dreamId) async {
    try {
      final success = await DreamApiService.likeDream(dreamId);
      if (success) {
        // 更新本地数据
        setState(() {
          final index = _dreamPosts.indexWhere((post) => post.id == dreamId);
          if (index != -1) {
            _dreamPosts[index] = _dreamPosts[index].copyWith(
              likes: _dreamPosts[index].likes + 1,
            );
          }
        });
      }
    } catch (e) {
      print('点赞失败: $e');
    }
  }

  List<DreamPost> get _filteredPosts {
    List<DreamPost> posts;
    
    if (_searchController.text.isNotEmpty) {
      posts = _searchResults;
    } else if (_selectedCategoryIndex == 0) {
      posts = _dreamPosts;
    } else {
      final selectedCategory = _categories[_selectedCategoryIndex];
      posts = _dreamPosts.where((post) => post.category == selectedCategory).toList();
    }
    
    // 确保帖子按发布时间降序排列（最新的在前）
    posts.sort((a, b) => b.publishTime.compareTo(a.publishTime));
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    return Scaffold(
      backgroundColor: Color(0xFF1a1c2e),
      body: Stack(
        children: [
          // 梦幻背景
          _buildDreamBackground(),
          
          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部搜索栏
                _buildSearchBar(),
                
                // 分类标签
                _buildCategoryTabs(),
                
                // 排序提示
                if (!_isLoading && _dreamPosts.isNotEmpty)
                  _buildSortIndicator(),
                
                // 瀑布流内容
                Expanded(
                  child: _buildDreamWaterfall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1c2e),
            Color(0xFF2d1b69),
            Color(0xFF11001a),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 星光效果
          ...List.generate(20, (index) {
            return Positioned(
              left: math.Random().nextDouble() * 400,
              top: math.Random().nextDouble() * 800,
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.5 + 0.5 * math.sin(_floatingController.value * 2 * math.pi + index * 0.5),
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '搜索梦境故事...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
              onChanged: (value) {
                _searchDreams(value);
              },
            ),
          ),
          if (_isSearching)
            Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (_searchController.text.isNotEmpty) {
                  _searchController.clear();
                  _searchDreams('');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _searchController.text.isNotEmpty ? Icons.clear : Icons.filter_list,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedCategoryIndex = index;
              });
              _loadDreams(); // 重新加载对应分类的数据
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '按最新发布时间排序',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamWaterfall() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
            ),
            SizedBox(height: 16),
            Text(
              '梦境加载中...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.7),
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!.contains('网络') ? '网络连接失败，请检查网络设置' : '服务器暂时不可用',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDreams,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    final posts = _filteredPosts;
    
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nights_stay_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty ? '没有找到相关梦境' : '暂无梦境数据',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDreams,
      color: Colors.white,
      backgroundColor: Colors.purple.shade300,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildDreamCard(posts[index]);
        },
      ),
    );
  }

  Widget _buildDreamCard(DreamPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    post.author.avatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.nickname,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(post.publishTime),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 内容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 图片
          if (post.imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white.withOpacity(0.5),
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // 标签
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 底部操作栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _likeDream(post.id);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likes.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.comments.toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: 实现分享功能
                  },
                  child: Icon(
                    Icons.share_outlined,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 