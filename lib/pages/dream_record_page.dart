import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'add_dream_page.dart';
import 'dream_detail_page.dart';

class DreamRecordPage extends StatefulWidget {
  const DreamRecordPage({super.key});

  @override
  State<DreamRecordPage> createState() => _DreamRecordPageState();
}

class _DreamRecordPageState extends State<DreamRecordPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<DreamRecord> _dreams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dreams = await _databaseService.getAllDreams();
      setState(() {
        _dreams = dreams;
        _isLoading = false;
      });
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

  Future<void> _deleteDream(int id) async {
    try {
      await _databaseService.deleteDream(id);
      await _loadDreams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '梦境记录',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _dreams.isEmpty
                ? const Center(
                    child: Text(
                      '暂无梦境记录',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    itemCount: _dreams.length,
                    itemBuilder: (context, index) {
                      final dream = _dreams[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            dream.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(
                              DateTime.parse(dream.time),
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteDream(dream.id!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
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
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDreamPage()),
          );
          if (result == true) {
            _loadDreams();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 