import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dream_models.dart';

class DreamApiService {
  static const String baseUrl = 'http://neuronx.top:3000'; // 您的服务器域名
  // 如果没有HTTPS，可以使用 'http://neuronx.top:3000'
  
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