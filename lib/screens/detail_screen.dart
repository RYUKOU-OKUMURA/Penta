import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';

/// 詳細画面（全画面表示＋コメント編集）
class DetailScreen extends StatefulWidget {
  final int photoIndex;

  const DetailScreen({
    super.key,
    required this.photoIndex,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late TextEditingController _commentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    final photo = storage.photos[widget.photoIndex];
    _commentController = TextEditingController(text: photo.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text('画像 ${widget.photoIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除',
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<StorageService>(
          builder: (context, storage, _) {
            if (widget.photoIndex >= storage.photoCount) {
              // 画像が削除された場合
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
              return const SizedBox.shrink();
            }

            final photo = storage.photos[widget.photoIndex];

            return Column(
              children: [
                // 画像表示エリア
                Expanded(
                  flex: 3,
                  child: Center(
                    child: FutureBuilder<dynamic>(
                      future: kIsWeb
                          ? storage.getImageData(photo.fileName)
                          : storage.getImagePath(photo.fileName),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator(
                            color: Colors.white,
                          );
                        }

                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: kIsWeb
                              ? Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildErrorImage(),
                                )
                              : Image.file(
                                  File(snapshot.data!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildErrorImage(),
                                ),
                        );
                      },
                    ),
                  ),
                ),

                // コメント編集エリア
                Container(
                  color: Colors.grey[900],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.comment,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'コメント',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isEditing)
                            TextButton(
                              onPressed: _saveComment,
                              child: const Text('保存'),
                            )
                          else
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: const Text('編集'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentController,
                        enabled: _isEditing,
                        maxLength: 200,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'コメントを入力...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          counterStyle: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// エラー画像表示
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              '画像を読み込めません',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// コメント保存
  void _saveComment() {
    final storage = context.read<StorageService>();
    storage.updateComment(widget.photoIndex, _commentController.text);
    
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('コメントを保存しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 削除確認ダイアログ
  Future<void> _showDeleteDialog(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この画像を削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final storage = context.read<StorageService>();
      await storage.deletePhoto(widget.photoIndex);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}
