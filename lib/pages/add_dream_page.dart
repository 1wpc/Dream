import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/jimeng_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class AddDreamPage extends StatefulWidget {
  const AddDreamPage({super.key});

  @override
  State<AddDreamPage> createState() => _AddDreamPageState();
}

class _AddDreamPageState extends State<AddDreamPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _databaseService = DatabaseService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _generateImage() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterDreamContent)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用梦境内容作为提示词
      final imageUrl = await JimengService.generateImage(_contentController.text);
      
      // 下载图片并保存到本地
      final response = await http.get(Uri.parse(imageUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/dream_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.generateImageFailed}：$e')),
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

  Future<void> _saveDream() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dream = DreamRecord(
        title: _titleController.text,
        content: _contentController.text,
        time: DateTime.now().toIso8601String(),
        imageUrl: _selectedImage?.path,
      );

      await _databaseService.insertDream(dream);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.saveFailed}：$e')),
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
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
        title: Text(
          AppLocalizations.of(context)!.recordDream,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDream,
            child: Text(
              AppLocalizations.of(context)!.save,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
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
                  Colors.blue.shade900,
                  Colors.blue.shade700,
                ],
              ),
            ),
          ),
          // 内容卡片
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.title,
                                hintStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.pleaseEnterTitle;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.content,
                                hintStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              maxLines: 8,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.pleaseEnterContent;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.photo_library),
                                    label: Text(AppLocalizations.of(context)!.selectImage),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade800.withOpacity(0.8),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _generateImage,
                                    icon: const Icon(Icons.auto_awesome),
                                    label: Text(AppLocalizations.of(context)!.aiGenerate),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade700.withOpacity(0.8),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedImage != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _selectedImage!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}