import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_item.dart';

/// ローカルストレージ管理サービス
class StorageService extends ChangeNotifier {
  static const String _photosKey = 'photo_gallery_photos';
  static const String _imagePrefix = 'photo_gallery_image_';
  static const int _maxPhotos = 5;
  
  SharedPreferences? _prefs;
  List<PhotoItem> _photos = [];

  List<PhotoItem> get photos => List.unmodifiable(_photos);
  int get photoCount => _photos.length;
  bool get canAddMore => _photos.length < _maxPhotos;
  int get remainingSlots => _maxPhotos - _photos.length;

  /// 初期化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPhotos();
  }

  /// 写真データを読み込む
  Future<void> _loadPhotos() async {
    if (_prefs == null) return;
    
    final String? photosJson = _prefs!.getString(_photosKey);
    if (photosJson == null) {
      _photos = [];
      notifyListeners();
      return;
    }

    try {
      final List<dynamic> photosList = jsonDecode(photosJson);
      _photos = photosList
          .map((item) => PhotoItem.fromMap(item as Map<String, dynamic>))
          .toList();
      
      // 並び順でソート
      _photos.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('写真データ読み込みエラー: $e');
      }
      _photos = [];
      notifyListeners();
    }
  }

  /// 写真データを保存
  Future<void> _savePhotos() async {
    if (_prefs == null) return;
    
    try {
      final photosJson = jsonEncode(_photos.map((p) => p.toMap()).toList());
      await _prefs!.setString(_photosKey, photosJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('写真データ保存エラー: $e');
      }
    }
  }

  /// 写真を追加
  Future<String?> addPhoto(Uint8List imageData, String fileName) async {
    if (!canAddMore) {
      return '最大5枚までしか保存できません';
    }

    try {
      // 画像を保存
      final success = await _saveImageFile(imageData, fileName);
      if (!success) {
        return '画像の保存に失敗しました';
      }

      // メタデータを作成
      final photoItem = PhotoItem(
        fileName: fileName,
        comment: '',
        createdAt: DateTime.now(),
        sortOrder: _photos.length,
      );

      _photos.add(photoItem);
      await _savePhotos();
      notifyListeners();
      
      return null; // 成功
    } catch (e) {
      if (kDebugMode) {
        debugPrint('写真追加エラー: $e');
      }
      return '予期しないエラーが発生しました';
    }
  }

  /// 画像ファイルを保存
  Future<bool> _saveImageFile(Uint8List imageData, String fileName) async {
    try {
      if (kIsWeb) {
        // Webの場合はBase64でSharedPreferencesに保存
        final base64Image = base64Encode(imageData);
        await _prefs?.setString('$_imagePrefix$fileName', base64Image);
        return true;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(imageData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ファイル保存エラー: $e');
      }
      return false;
    }
  }

  /// 画像データを取得
  Future<Uint8List?> getImageData(String fileName) async {
    try {
      if (kIsWeb) {
        final base64Image = _prefs?.getString('$_imagePrefix$fileName');
        if (base64Image != null) {
          return base64Decode(base64Image);
        }
        return null;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('画像読み込みエラー: $e');
      }
      return null;
    }
  }

  /// コメントを更新
  Future<void> updateComment(int index, String comment) async {
    if (index < 0 || index >= _photos.length) return;
    
    _photos[index].comment = comment;
    await _savePhotos();
    notifyListeners();
  }

  /// 写真を削除
  Future<void> deletePhoto(int index) async {
    if (index < 0 || index >= _photos.length) return;

    final photo = _photos[index];
    
    // ファイルを削除
    await _deleteImageFile(photo.fileName);
    
    // リストから削除
    _photos.removeAt(index);
    
    // 並び順を再調整
    await _reorderPhotos();
  }

  /// 全写真を削除
  Future<void> deleteAllPhotos() async {
    // すべてのファイルを削除
    for (var photo in _photos) {
      await _deleteImageFile(photo.fileName);
    }
    
    _photos.clear();
    await _prefs?.remove(_photosKey);
    notifyListeners();
  }

  /// 画像ファイルを削除
  Future<void> _deleteImageFile(String fileName) async {
    try {
      if (kIsWeb) {
        await _prefs?.remove('$_imagePrefix$fileName');
        return;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ファイル削除エラー: $e');
      }
    }
  }

  /// 写真の順序を変更
  Future<void> reorderPhotos(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    
    final item = _photos.removeAt(oldIndex);
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _photos.insert(adjustedIndex, item);
    
    await _reorderPhotos();
  }

  /// 並び順を再調整して保存
  Future<void> _reorderPhotos() async {
    for (var i = 0; i < _photos.length; i++) {
      _photos[i].sortOrder = i;
    }
    await _savePhotos();
    notifyListeners();
  }

  /// 画像ファイルのパスを取得
  Future<String> getImagePath(String fileName) async {
    if (kIsWeb) {
      return fileName; // Web版は直接使用
    }
    
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }
}
