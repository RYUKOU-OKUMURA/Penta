# Penta - 5枚だけギャラリーアプリ

<div align="center">

![Penta Logo](web/icons/Icon-192.png)

**シンプル、ミニマル、5枚だけ。**

大切な写真を厳選して保存する、新しいフォトギャラリー体験。

[🌐 Web Demo](https://5060-i3zpe1hd1vkkq83jptnvz-b9b802c4.sandbox.novita.ai) | [📱 Download APK](#) | [📖 Documentation](#features)

</div>

---

## ✨ Features

### 📸 5枚制限のシンプルギャラリー
- **最大5枚まで**の写真保存で、本当に大切な写真だけを厳選
- グリッド形式の見やすい一覧表示
- 画像ごとにコメント（最大200文字）を追加可能

### 🎨 直感的な操作
- ドラッグ&ドロップで簡単に並び替え
- タップで全画面表示
- ピンチイン/アウトでズーム操作
- 長押しで削除メニュー表示

### 💾 オフライン完結
- すべてのデータを端末内に保存
- ネットワーク接続不要
- プライバシー重視の設計

### 🌈 洗練されたデザイン
- Material Design 3採用
- 紫とブルーのグラデーションテーマ
- ダークモード対応（将来予定）

---

## 📱 Screenshots

| ギャラリー画面 | 詳細画面 | コメント編集 |
|:---:|:---:|:---:|
| *写真一覧とグリッド表示* | *全画面表示とズーム* | *コメント追加機能* |

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.35.4以降
- Dart 3.9.2以降

### Installation

```bash
# リポジトリをクローン
git clone https://github.com/RYUKOU-OKUMURA/Penta.git
cd Penta

# 依存関係をインストール
flutter pub get

# アプリを実行
flutter run
```

### Web版のビルド

```bash
# Webアプリをビルド
flutter build web --release

# ローカルサーバーで起動
cd build/web
python3 -m http.server 5060
```

http://localhost:5060 でアクセス可能

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # アプリエントリーポイント
├── models/
│   └── photo_item.dart         # 画像データモデル
├── services/
│   └── storage_service.dart    # ストレージ管理サービス
└── screens/
    ├── gallery_screen.dart     # ギャラリー画面
    └── detail_screen.dart      # 詳細画面
```

---

## 🎯 Core Concepts

### なぜ「5枚だけ」？

- **厳選する楽しさ**: 無限にある写真の中から、本当に大切な5枚を選ぶ体験
- **シンプルさの追求**: 多機能ではなく、一つのコンセプトを徹底
- **記憶に残る**: 5枚だからこそ、一枚一枚に意味を持たせられる

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.35.4
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Image Handling**: Image Picker
- **UI Design**: Material Design 3

---

## 📋 Roadmap

### v0.1 (現在) ✅
- [x] 5枚制限の画像保存
- [x] グリッド表示
- [x] 全画面表示
- [x] コメント機能
- [x] 並び替え
- [x] 削除機能

### v0.2 (予定)
- [ ] ダークモード対応
- [ ] 画像のタグ付け
- [ ] エクスポート機能
- [ ] 共有機能

### v1.0 (将来)
- [ ] クラウド同期（オプション）
- [ ] ウィジェット対応
- [ ] アニメーション強化

---

## 🤝 Contributing

プルリクエストを歓迎します！大きな変更の場合は、まずIssueを開いて変更内容を議論してください。

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) をご覧ください。

---

## 👤 Author

**RYUKOU OKUMURA**

- 🌐 整体院経営者・AIコンテンツクリエイター
- 📺 YouTube: [AI整体師チャンネル](https://youtube.com/@ai-seitaishi)
- 📧 お問い合わせ: [GitHub Issues](https://github.com/RYUKOU-OKUMURA/Penta/issues)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the design guidelines
- All contributors and users

---

<div align="center">

**Made with ❤️ by BOSS**

[⭐ Star this repo](https://github.com/RYUKOU-OKUMURA/Penta) if you like it!

</div>
