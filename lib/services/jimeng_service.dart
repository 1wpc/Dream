import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utills/env.dart';

class JimengService {
  static const String _baseUrl = 'visual.volcengineapi.com';
  static const String _endpoint = 'https://visual.volcengineapi.com';
  static const String _action = 'CVProcess';
  static const String _version = '2022-08-31';
  static const String _reqKey = 'jimeng_high_aes_general_v21_L';
  
  // 火山引擎认证信息
  static final String _accessKeyId = Env.jimengKeyId;
  static final String _secretAccessKey = Env.jimengScKey;
  static const String _region = 'cn-north-1';
  static const String _service = 'cv';

  // 签名函数
  static Uint8List _sign(Uint8List key, String msg) {
    return Uint8List.fromList(Hmac(sha256, key).convert(utf8.encode(msg)).bytes);
  }

  // 获取签名密钥
  static Uint8List _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = _sign(Uint8List.fromList(utf8.encode(key)), dateStamp);
    final kRegion = _sign(kDate, regionName);
    final kService = _sign(kRegion, serviceName);
    return _sign(kService, 'request');
  }

  // 格式化查询参数
  static String _formatQuery(Map<String, String> parameters) {
    final sortedParams = Map.fromEntries(
      parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    return sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }

  // 生成签名
  static Map<String, String> _signV4Request(
    String accessKey,
    String secretKey,
    String service,
    String reqQuery,
    String reqBody,
  ) {
    final t = DateTime.now().toUtc();
    final formattedDate = '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}T'
        '${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}${t.second.toString().padLeft(2, '0')}Z';
    final datestamp = formattedDate.substring(0, 8);
    
    final canonicalUri = '/';
    final signedHeaders = 'content-type;host;x-content-sha256;x-date';
    final payloadHash = sha256.convert(utf8.encode(reqBody)).toString();
    final contentType = 'application/json';
    
    final canonicalHeaders = [
      'content-type:$contentType',
      'host:$_baseUrl',
      'x-content-sha256:$payloadHash',
      'x-date:$formattedDate'
    ].join('\n') + '\n\n' + signedHeaders + '\n' + payloadHash;

    final canonicalRequest = [
      'POST',
      canonicalUri,
      reqQuery,
      canonicalHeaders
    ].join('\n');

    final algorithm = 'HMAC-SHA256';
    final credentialScope = '$datestamp/$_region/$service/request';
    final stringToSign = [
      algorithm,
      formattedDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString()
    ].join('\n');

    final signingKey = _getSignatureKey(secretKey, datestamp, _region, service);
    final signature = Hmac(sha256, signingKey)
        .convert(utf8.encode(stringToSign))
        .bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    final authorizationHeader = '$algorithm Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    return {
      'X-Date': formattedDate,
      'Authorization': authorizationHeader,
      'X-Content-Sha256': payloadHash,
      'Content-Type': contentType,
    };
  }

  // 生成图片
  static Future<String> generateImage(String prompt) async {
    try {
      final queryParams = {
        'Action': _action,
        'Version': _version,
      };
      final formattedQuery = _formatQuery(queryParams);

      final bodyParams = {
        'req_key': _reqKey,
        'prompt': prompt,
        'width': 288,
        'height': 512,
        'use_pre_llm': true,
        'use_sr': true,
        'return_url': true,
      };
      final formattedBody = jsonEncode(bodyParams);

      final headers = _signV4Request(
        _accessKeyId,
        _secretAccessKey,
        _service,
        formattedQuery,
        formattedBody,
      );


      final dio = Dio();
      final response = await dio.post(
        '$_endpoint?$formattedQuery',
        data: formattedBody,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 10000) {
          final imageUrls = data['data']['image_urls'] as List;
          if (imageUrls.isNotEmpty) {
            return imageUrls[0];
          }
        }
        throw Exception('生成图片失败: ${data['message']}');
      } else {
        // debugPrint('请求详情：');
        // debugPrint('URL: $_endpoint?$formattedQuery');
        // debugPrint('Headers: $headers');
        // debugPrint('Body: $formattedBody');
        // debugPrint('Response: ${response.data}');
        throw Exception('API请求失败: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      throw Exception('生成图片失败: $e');
    }
  }

  // 批量生成图片
  static Future<List<String>> generateImages(List<String> prompts) async {
    final List<String> imageUrls = [];
    for (final prompt in prompts) {
      try {
        final imageUrl = await generateImage(prompt);
        imageUrls.add(imageUrl);
      } catch (e) {
        debugPrint('生成图片失败: $e');
        // 继续处理下一个提示词
      }
    }
    return imageUrls;
  }
} 