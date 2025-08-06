import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ZhougongDreamPage extends StatefulWidget {
  const ZhougongDreamPage({super.key});

  @override
  State<ZhougongDreamPage> createState() => _ZhougongDreamPageState();
}

class _ZhougongDreamPageState extends State<ZhougongDreamPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _dreamResult;
  bool _isSearching = false;
  String? _dreamTitle;
  String _errorMessage = '';

  // 热门梦境关键词
  final List<String> _hotKeywords = [
    '蛇', '飞', '水', '钱', '死亡',
    '考试', '婚礼', '追赶', '迷路', '牙齿掉落',
    '自行车', '鲜花'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 在线搜索解梦
  Future<void> _searchDream() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _dreamResult = null;
        _dreamTitle = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final result = await _fetchDreamInterpretation(keyword);
      
      setState(() {
        _isSearching = false;
        if (result != null) {
          _dreamResult = result['content'];
          _dreamTitle = result['title'];
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = '${AppLocalizations.of(context)!.queryFailed}：$e';
        _dreamResult = null;
        _dreamTitle = null;
      });
    }
  }

  // 调用在线周公解梦API
  Future<Map<String, dynamic>?> _fetchDreamInterpretation(String keyword) async {
    const url = "https://eolink.o.apispace.com/zgjm/common/dream/searchDreamDetail";
    
    // 构建请求
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "X-APISpace-Token": "z9bxlrwngndwk50tmpva5khsyxswc3lq",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "keyword": keyword
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['statusCode'] == '000000' && data['result'] != null && data['result'].isNotEmpty) {
        // 返回第一条结果
        return data['result'][0];
      } else {
        throw Exception('未找到相关解梦内容');
      }
    } else {
      throw Exception('${AppLocalizations.of(context)!.apiRequestFailedStatus}: ${response.statusCode}');
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
        title: const Text(
          '周公解梦',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.indigo.shade900,
                  Colors.indigo.shade700,
                ],
              ),
            ),
          ),
          // 主内容
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索框
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: '输入梦境关键词，如：蛇、水、飞...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => _searchDream(),
                          ),
                        ),
                        IconButton(
                          onPressed: _searchDream,
                          icon: const Icon(Icons.search, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // 解梦结果
                  if (_isSearching)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    )
                  else if (_dreamResult != null) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dreamTitle ?? '梦境解析',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 使用正则表达式移除HTML标签
                          Text(
                            _dreamResult!.replaceAll(RegExp(r'<[^>]*>'), ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 热门梦境关键词
                    const Text(
                      '热门梦境关键词',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _hotKeywords.map((keyword) => ActionChip(
                        label: Text(keyword),
                        onPressed: () {
                          _searchController.text = keyword;
                          _searchDream();
                        },
                        backgroundColor: Colors.white.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                      )).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 解梦小知识
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '解梦小知识',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.dreamKnowledgeContent,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}