import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/dream_models.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _isLoading = false;
  DreamUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUser = authService.userProfile;
  }

  // 显示编辑弹窗
  Future<void> _showEditDialog(String title, String currentValue, String field, {int maxLines = 1, int? maxLength, String? Function(String?)? validator}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentValue);
        return AlertDialog(
          title: Text('编辑$title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
              hintText: '请输入$title',
              border: const OutlineInputBorder(),
            ),
            maxLines: maxLines,
            maxLength: maxLength,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (validator != null) {
                  final error = validator(value);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.red),
                    );
                    return;
                  }
                }
                Navigator.pop(context, value);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      await _updateField(field, result);
    }
  }
  
  // 更新单个字段
  Future<void> _updateField(String field, String value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      bool success = false;
      switch (field) {
        case 'nickname':
          success = await authService.updateUserProfile(
            nickname: value,
            bio: _currentUser?.bio,
            phone: _currentUser?.phone,
          );
          break;
        case 'bio':
          success = await authService.updateUserProfile(
            nickname: _currentUser?.nickname ?? '',
            bio: value,
            phone: _currentUser?.phone,
          );
          break;
        case 'phone':
          success = await authService.updateUserProfile(
            nickname: _currentUser?.nickname ?? '',
            bio: _currentUser?.bio,
            phone: value,
          );
          break;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新成功'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserData(); // 重新加载数据
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('编辑资料'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 头像区域
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Stack(
                      children: [
                        ClipOval(
                           child: _currentUser?.avatar != null
                               ? CachedNetworkImage(
                                   imageUrl: _currentUser!.avatar,
                                   width: 96,
                                   height: 96,
                                   fit: BoxFit.cover,
                                   placeholder: (context, url) => const CircularProgressIndicator(),
                                   errorWidget: (context, url, error) => const Icon(
                                     Icons.person,
                                     size: 50,
                                     color: Colors.grey,
                                   ),
                                 )
                               : const Icon(
                                   Icons.person,
                                   size: 50,
                                   color: Colors.grey,
                                 ),
                         ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 个人信息列表
                  Card(
                    color: const Color(0xFF16213E),
                    child: Column(
                      children: [
                        // 昵称
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.white70),
                          title: const Text(
                            '昵称',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _currentUser?.nickname ?? '未设置',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                          onTap: () => _showEditDialog(
                            '昵称',
                            _currentUser?.nickname ?? '',
                            'nickname',
                            maxLength: 20,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入昵称';
                              }
                              if (value.trim().length > 20) {
                                return '昵称不能超过20个字符';
                              }
                              return null;
                            },
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        // 个人简介
                        ListTile(
                          leading: const Icon(Icons.description, color: Colors.white70),
                          title: const Text(
                            '个人简介',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _currentUser?.bio?.isNotEmpty == true ? _currentUser!.bio! : '未设置',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                          onTap: () => _showEditDialog(
                            '个人简介',
                            _currentUser?.bio ?? '',
                            'bio',
                            maxLines: 3,
                            maxLength: 100,
                            validator: (value) {
                              if (value != null && value.trim().length > 100) {
                                return '个人简介不能超过100个字符';
                              }
                              return null;
                            },
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        // 手机号
                        ListTile(
                          leading: const Icon(Icons.phone, color: Colors.white70),
                          title: const Text(
                            '手机号',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _currentUser?.phone?.isNotEmpty == true ? _currentUser!.phone! : '未设置',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                          onTap: () => _showEditDialog(
                            '手机号',
                            _currentUser?.phone ?? '',
                            'phone',
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value.trim())) {
                                  return '请输入正确的手机号格式';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 账户信息卡片
                  Card(
                    color: const Color(0xFF16213E),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '账户信息',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '邮箱: ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Expanded(
                                child: Text(
                                  _currentUser?.email ?? '未设置',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '注册时间: ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Expanded(
                                child: Text(
                                  _currentUser?.createdAt != null
                                       ? DateFormat('yyyy-MM-dd HH:mm').format(_currentUser!.createdAt!)
                                       : '未知',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  

}