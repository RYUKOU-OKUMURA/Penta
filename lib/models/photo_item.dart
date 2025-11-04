/// 画像アイテムのデータモデル
/// 画像ファイルパス、コメント、作成日時を管理
class PhotoItem {
  /// 画像ファイル名（UUID + 拡張子）
  String fileName;

  /// 画像に紐づくコメント（最大200文字）
  String comment;

  /// 作成日時
  DateTime createdAt;

  /// 並び順インデックス（0から始まる）
  int sortOrder;

  PhotoItem({
    required this.fileName,
    this.comment = '',
    required this.createdAt,
    required this.sortOrder,
  });

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  /// Map形式から復元
  factory PhotoItem.fromMap(Map<String, dynamic> map) {
    return PhotoItem(
      fileName: map['fileName'] as String,
      comment: map['comment'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      sortOrder: map['sortOrder'] as int,
    );
  }

  /// コピーを作成
  PhotoItem copyWith({
    String? fileName,
    String? comment,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return PhotoItem(
      fileName: fileName ?? this.fileName,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
