import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class JimengService {
  // 后端统一生成图片接口
  static const String _imagePath = '/api/v1/generate/image';

  /// 生成单张图片，返回图片 URL
  static Future<String> generateImage(String prompt) async {
    try {
      final dio = ApiService.dio;
      final response = await dio.post(
        _imagePath,
        data: {
          'prompt': prompt,
          'use_sr': true,
          'width': 443,
          'height': 591,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // 兼容不同字段名
        if (data is Map && data.isNotEmpty) {
          if (data.containsKey('url')) return data['url'] as String;
          if (data.containsKey('image_url')) return data['image_url'] as String;
          if (data.containsKey('imageUrls')) return (data['imageUrls'] as List).first as String;
          if (data.containsKey('image_urls')) return (data['image_urls'] as List).first as String;
        }
        throw Exception('接口返回格式异常');
      }
      throw Exception('API请求失败: ${response.statusCode}');
    } catch (e) {
      throw Exception('生成图片失败: $e');
    }
  }

  /// 批量生成图片
  static Future<List<String>> generateImages(List<String> prompts) async {
    final List<String> imageUrls = [];
    for (final prompt in prompts) {
      try {
        final imageUrl = await generateImage(prompt);
        imageUrls.add(imageUrl);
      } catch (e) {
        debugPrint('生成图片失败: $e');
        // 添加占位符URL，确保返回的数量与prompts一致
        imageUrls.add('https://via.placeholder.com/512x512/cccccc/666666?text=生成失败');
      }
    }
    return imageUrls;
  }
}