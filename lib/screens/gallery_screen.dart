import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';
import 'detail_screen.dart';

/// ギャラリー画面（メイン画面）
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5枚だけギャラリー'),
        actions: [
          Consumer<StorageService>(
            builder: (context, storage, _) {
              if (storage.photoCount == 0) return const SizedBox.shrink();
              
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '全削除',
                onPressed: () => _showDeleteAllDialog(context),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<StorageService>(
                builder: (context, storage, _) {
                  if (storage.photoCount == 0) {
                    return _buildEmptyState();
                  }
                  
                  return _buildPhotoGrid(context, storage);
                },
              ),
            ),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'まだ画像がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「追加」ボタンから保存できます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 写真グリッド表示
  Widget _buildPhotoGrid(BuildContext context, StorageService storage) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: storage.photoCount,
      onReorder: (oldIndex, newIndex) {
        storage.reorderPhotos(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final photo = storage.photos[index];
        
        return Card(
          key: ValueKey(photo.fileName),
          margin: const EdgeInsets.all(4),
          child: InkWell(
            onTap: () => _navigateToDetail(context, index),
            onLongPress: () => _showDeleteDialog(context, index),
            child: Stack(
              children: [
                // 画像表示
                AspectRatio(
                  aspectRatio: 1,
                  child: FutureBuilder<dynamic>(
                    future: kIsWeb
                        ? storage.getImageData(photo.fileName)
                        : storage.getImagePath(photo.fileName),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (kIsWeb) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildErrorImage(),
                        );
                      } else {
                        return Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildErrorImage(),
                        );
                      }
                    },
                  ),
                ),
                
                // コメントありアイコン
                if (photo.comment.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.comment,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                
                // 並び順番号
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// エラー画像表示
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 追加ボタン
  Widget _buildAddButton() {
    return Consumer<StorageService>(
      builder: (context, storage, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: storage.canAddMore
                ? () => _pickImage(context)
                : null,
            icon: const Icon(Icons.add_a_photo),
            label: Text(
              '画像を追加 (${storage.photoCount}/5)',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 詳細画面へ遷移
  void _navigateToDetail(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(photoIndex: index),
      ),
    );
  }

  /// 画像選択
  Future<void> _pickImage(BuildContext context) async {
    final storage = context.read<StorageService>();
    
    if (!storage.canAddMore) {
      _showMaxPhotosDialog(context);
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return;

      // 画像データを読み込み
      final bytes = await image.readAsBytes();
      
      // ファイル名を生成
      final extension = image.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$extension';

      // 保存
      final error = await storage.addPhoto(bytes, fileName);
      
      if (error != null && context.mounted) {
        _showErrorDialog(context, error);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('画像選択エラー: $e');
      }
      if (context.mounted) {
        _showErrorDialog(context, '画像の読み込みに失敗しました');
      }
    }
  }

  /// 最大枚数到達ダイアログ
  void _showMaxPhotosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('制限到達'),
        content: const Text('5枚までしか保存できません。\n新しい画像を追加するには、既存の画像を削除してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// エラーダイアログ
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 削除確認ダイアログ
  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この画像を削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              context.read<StorageService>().deletePhoto(index);
              Navigator.pop(context);
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 全削除確認ダイアログ
  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全削除確認'),
        content: const Text('すべての画像を削除しますか?\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              context.read<StorageService>().deleteAllPhotos();
              Navigator.pop(context);
            },
            child: const Text(
              '全削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
