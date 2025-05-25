import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dream_models.dart';
import 'database_service.dart';

class DreamApiService {
  static const String baseUrl = 'http://neuronx.top:3000';
  
  // 获取所有梦境
  static Future<List<DreamPost>> getDreams({
    String? category,
    int? page,
    int limit = 20,
  }) async {
    try {
      String url = '$baseUrl/dreams';
      
      // 构建查询参数
      List<String> queryParams = [];
      if (category != null && category != '全部') {
        queryParams.add('category=$category');
      }
      if (page != null) {
        queryParams.add('_page=$page');
      }
      queryParams.add('_limit=$limit');
      queryParams.add('_sort=publishTime');
      queryParams.add('_order=desc');
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }
      
      print('API请求: $url'); // 调试信息
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      print('API响应状态: ${response.statusCode}'); // 调试信息
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DreamPost.fromJson(item)).toList();
      } else {
        print('API错误: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load dreams: ${response.statusCode}');
      }
    } catch (e) {
      print('网络请求异常: $e');
      throw Exception('网络连接失败: $e');
    }
  }
  
  // 获取单个梦境详情
  static Future<DreamPost> getDreamById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dreams/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return DreamPost.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load dream details');
      }
    } catch (e) {
      throw Exception('网络连接失败: $e');
    }
  }
  
  // 创建新梦境
  static Future<DreamPost> createDream(Map<String, dynamic> dreamData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dreams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dreamData),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        return DreamPost.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create dream');
      }
    } catch (e) {
      throw Exception('创建梦境失败: $e');
    }
  }

  // 分享梦境到社区 - 核心新功能
  static Future<DreamPost> shareDreamToCommunity({
    required DreamRecord dreamRecord,
    required String category,
    required List<String> tags,
    String? customImageUrl,
    String authorNickname = '匿名梦想家',
    String authorAvatar = '',
  }) async {
    try {
      // 构建社区帖子数据
      final dreamData = {
        'title': dreamRecord.title,
        'content': dreamRecord.content,
        'imageUrl': customImageUrl ?? dreamRecord.imageUrl ?? '',
        'author': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'nickname': authorNickname,
          'avatar': authorAvatar.isNotEmpty ? authorAvatar : 'https://images.unsplash.com/photo-1494790108755-2616c2b13948?w=100',
          'dreamCount': 1,
        },
        'likes': 0,
        'comments': 0,
        'tags': tags,
        'publishTime': DateTime.now().toIso8601String(),
        'category': category,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/dreams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dreamData),
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 201) {
        final createdPost = DreamPost.fromJson(json.decode(response.body));
        print('梦境分享成功: ${createdPost.id}');
        return createdPost;
      } else {
        print('API错误: ${response.statusCode} - ${response.body}');
        throw Exception('分享失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('分享梦境异常: $e');
      throw Exception('分享到社区失败: $e');
    }
  }

  // 快速分享梦境到社区（自动推断分类和标签）
  static Future<DreamPost> quickShareDream({
    required DreamRecord dreamRecord,
    String authorNickname = '匿名梦想家',
    String? customImageUrl,
  }) async {
    // 根据内容自动推断分类
    String category = _inferCategory(dreamRecord.title, dreamRecord.content);
    
    // 根据内容自动生成标签
    List<String> tags = _generateTags(dreamRecord.title, dreamRecord.content);
    
    return await shareDreamToCommunity(
      dreamRecord: dreamRecord,
      category: category,
      tags: tags,
      customImageUrl: customImageUrl,
      authorNickname: authorNickname,
    );
  }

  // 私有方法：推断梦境分类
  static String _inferCategory(String title, String content) {
    final text = (title + ' ' + content).toLowerCase();
    
    if (text.contains(RegExp(r'机器|科技|网络|未来|虚拟|数字|赛博|电脑'))) {
      return '赛博朋克';
    } else if (text.contains(RegExp(r'森林|花|海|山|动物|自然|树|河|天空|星'))) {
      return '自然';
    } else if (text.contains(RegExp(r'魔法|龙|精灵|城堡|法师|魔幻|仙女|巫师'))) {
      return '奇幻';
    } else if (text.contains(RegExp(r'老式|复古|过去|童年|回忆|怀旧|古老'))) {
      return '复古';
    } else if (text.contains(RegExp(r'宁静|冥想|禅|平和|安静|简单|空灵'))) {
      return '禅意';
    } else if (text.contains(RegExp(r'奇异|超现实|变形|漂浮|不可能|诡异|扭曲'))) {
      return '超现实';
    } else if (text.contains(RegExp(r'温暖|治愈|美好|幸福|快乐|舒适|甜蜜'))) {
      return '治愈';
    } else if (text.contains(RegExp(r'冒险|探索|旅行|发现|挑战|勇敢|征服'))) {
      return '冒险';
    }
    
    return '奇幻'; // 默认分类
  }

  // 私有方法：生成标签
  static List<String> _generateTags(String title, String content) {
    final text = (title + ' ' + content).toLowerCase();
    List<String> tags = [];
    
    // 情感标签
    if (text.contains(RegExp(r'恐惧|害怕|紧张|焦虑'))) tags.add('恐惧');
    if (text.contains(RegExp(r'快乐|开心|高兴|兴奋'))) tags.add('快乐');
    if (text.contains(RegExp(r'爱|喜欢|浪漫|温暖'))) tags.add('爱情');
    if (text.contains(RegExp(r'悲伤|难过|哭|眼泪'))) tags.add('悲伤');
    
    // 场景标签
    if (text.contains(RegExp(r'学校|老师|同学|考试'))) tags.add('校园');
    if (text.contains(RegExp(r'家|父母|亲人|童年'))) tags.add('家庭');
    if (text.contains(RegExp(r'工作|同事|老板|公司'))) tags.add('职场');
    if (text.contains(RegExp(r'飞|翔|天空|云'))) tags.add('飞翔');
    if (text.contains(RegExp(r'水|游泳|海|河'))) tags.add('水');
    if (text.contains(RegExp(r'追|跑|逃|被追'))) tags.add('追逐');
    
    // 如果没有标签，添加默认标签
    if (tags.isEmpty) {
      tags.addAll(['梦境', '记录']);
    }
    
    // 限制标签数量
    return tags.take(5).toList();
  }
  
  // 点赞梦境
  static Future<bool> likeDream(String dreamId) async {
    try {
      // 先获取当前梦境数据
      final dream = await getDreamById(dreamId);
      
      // 更新点赞数
      final updatedData = {
        'likes': dream.likes + 1,
      };
      
      final response = await http.patch(
        Uri.parse('$baseUrl/dreams/$dreamId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedData),
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('点赞失败: $e');
      return false;
    }
  }
  
  // 获取用户信息
  static Future<List<DreamUser>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DreamUser.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }
  
  // 获取评论
  static Future<List<DreamComment>> getComments(String dreamId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments?dreamId=$dreamId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DreamComment.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      throw Exception('获取评论失败: $e');
    }
  }
  
  // 搜索梦境
  static Future<List<DreamPost>> searchDreams(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dreams?q=$query'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DreamPost.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search dreams');
      }
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }
} 