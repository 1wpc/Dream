import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/dream_models.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
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
    
    if (_currentUser != null) {
      _nicknameController.text = _currentUser!.nickname;
      _bioController.text = _currentUser!.bio ?? '';
      _phoneController.text = _currentUser!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final success = await authService.updateUserProfile(
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息更新成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 返回true表示有更新
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
      appBar: AppBar(
        title: const Text('编辑个人信息'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 头像部分
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _currentUser?.avatar.isNotEmpty == true
                        ? NetworkImage(_currentUser!.avatar)
                        : null,
                    child: _currentUser?.avatar.isEmpty != false
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: 实现头像上传功能
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('头像上传功能待实现'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // 昵称输入框
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                hintText: '请输入昵称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入昵称';
                }
                if (value.trim().length < 2) {
                  return '昵称至少需要2个字符';
                }
                if (value.trim().length > 20) {
                  return '昵称不能超过20个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 个人简介输入框
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '个人简介',
                hintText: '介绍一下自己吧',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              maxLength: 100,
              validator: (value) {
                if (value != null && value.length > 100) {
                  return '个人简介不能超过100个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 手机号输入框
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号',
                hintText: '请输入手机号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // 简单的手机号验证
                  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                    return '请输入正确的手机号格式';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // 用户信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '账户信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentUser?.email != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text('邮箱: ${_currentUser!.email}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.stars_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('积分: ${_currentUser?.points ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '注册时间: ${_currentUser?.createdAt != null ? _formatDate(_currentUser!.createdAt!) : "未知"}',
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
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}