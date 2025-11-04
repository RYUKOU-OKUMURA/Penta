# Google Play Store 公開トラブルシューティングガイド

## 📋 目次
1. [署名エラー](#署名エラー)
2. [パッケージ名エラー](#パッケージ名エラー)
3. [ビルド設定](#ビルド設定)
4. [チェックリスト](#公開前チェックリスト)

---

## 🔐 署名エラー

### エラー1: デバッグモード署名
```
アップロードされた APK または Android App Bundle がデバッグモードで署名されています。
APK または Android App Bundle はリリースモードで署名する必要があります。
```

#### 原因
- デフォルトのFlutterプロジェクトはデバッグキーで署名される
- リリース用の署名キーが未設定

#### 解決方法

**ステップ1: 署名キーの生成**
```bash
cd /path/to/your/flutter_app/android/app
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass [強力なパスワード] \
  -keypass [強力なパスワード] \
  -dname "CN=YourAppName, OU=Development, O=YourCompany, L=YourCity, ST=YourState, C=JP"
```

**重要**: 
- `upload-keystore.jks` ファイルを**安全に保管**
- パスワードを**忘れないように記録**
- このキーを紛失すると、アプリの更新ができなくなります

**ステップ2: key.properties ファイル作成**

`android/key.properties` を作成:
```properties
storePassword=[あなたのパスワード]
keyPassword=[あなたのパスワード]
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**ステップ3: build.gradle.kts 更新**

`android/app/build.gradle.kts` の先頭に追加:
```kotlin
import java.util.Properties
import java.io.FileInputStream

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
```

`android` ブロック内に追加:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties.getProperty("keyAlias")
        keyPassword = keystoreProperties.getProperty("keyPassword")
        storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
        storePassword = keystoreProperties.getProperty("storePassword")
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

**ステップ4: .gitignore 更新**

`.gitignore` に追加（キーを誤ってコミットしないため）:
```
# Android signing keys
/android/key.properties
/android/app/upload-keystore.jks
*.jks
*.keystore
```

**ステップ5: リビルド**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

**署名確認**
```bash
# APK署名確認
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk

# 証明書情報が表示されればOK
# Signer #1 certificate DN: CN=YourAppName, ...
```

---

## 📦 パッケージ名エラー

### エラー2: com.example パッケージ名制限
```
「com.example」は制限されているため、別のパッケージ名を使用する必要があります。
```

#### 原因
- Flutterのデフォルトパッケージ名が `com.example.appname`
- Google Playは `com.example.*` を制限

#### 解決方法

**ステップ1: パッケージ名を決定**

推奨フォーマット:
- `com.yourcompany.appname`
- `com.yourname.appname`
- `jp.co.yourcompany.appname`

例: `com.penta.app`

**ステップ2: build.gradle.kts 更新**

`android/app/build.gradle.kts`:
```kotlin
android {
    namespace = "com.penta.app"  // 旧: com.example.penta
    
    defaultConfig {
        applicationId = "com.penta.app"  // 旧: com.example.penta
        // ...
    }
}
```

**ステップ3: MainActivity ファイル移動**

```bash
# 現在のパッケージ構造
android/app/src/main/kotlin/com/example/penta/MainActivity.kt

# 新しいディレクトリ作成
mkdir -p android/app/src/main/kotlin/com/penta/app

# MainActivity.kt の package 宣言を更新
# 旧: package com.example.penta
# 新: package com.penta.app

# ファイル移動
mv android/app/src/main/kotlin/com/example/penta/MainActivity.kt \
   android/app/src/main/kotlin/com/penta/app/MainActivity.kt

# 古いディレクトリ削除
rm -rf android/app/src/main/kotlin/com/example
```

**MainActivity.kt の内容**:
```kotlin
package com.penta.app  // 更新

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

**ステップ4: リビルド**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**パッケージ名確認**
```bash
# AABのパッケージ名確認
$ANDROID_HOME/build-tools/35.0.0/aapt dump badging \
  build/app/outputs/flutter-apk/app-release.apk | grep package

# 出力例:
# package: name='com.penta.app' versionCode='1' ...
```

---

## ⚙️ ビルド設定

### 推奨ビルドコマンド

**App Bundle（推奨）**
```bash
flutter build appbundle --release
```
- Google Playが推奨する形式
- 各デバイスに最適化されたAPKを自動生成
- ファイルサイズが小さい

**APK（直接配布用）**
```bash
flutter build apk --release
```
- 直接インストール可能
- テスト配布に便利

### ビルドエラー対処法

**Gradleデーモンクラッシュ**
```bash
cd android
./gradlew --stop
cd ..
flutter clean
flutter build appbundle --release
```

**キャッシュクリア**
```bash
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
```

**Android ビルドのみクリーン**
```bash
cd android
./gradlew clean
cd ..
flutter build appbundle --release
```

---

## ✅ 公開前チェックリスト

### 必須項目

- [ ] **リリース署名の設定**
  - upload-keystore.jks 作成済み
  - key.properties 設定済み
  - build.gradle.kts に signingConfigs 追加済み

- [ ] **パッケージ名の変更**
  - com.example.* から変更済み
  - applicationId 更新済み
  - namespace 更新済み
  - MainActivity のパッケージ宣言更新済み

- [ ] **アプリ名の設定**
  - android/app/src/main/res/values/strings.xml 作成
  - AndroidManifest.xml で @string/app_name 使用

- [ ] **アプリアイコンの設定**
  - カスタムアイコン作成済み
  - 各解像度対応済み

- [ ] **バージョン情報**
  - pubspec.yaml の version 設定
  - versionCode と versionName 確認

- [ ] **ビルド成功確認**
  - `flutter build appbundle --release` 成功
  - `flutter build apk --release` 成功

### Google Play Console 設定項目

- [ ] **アプリ情報**
  - アプリ名（30文字以内）
  - 簡単な説明（80文字以内）
  - 詳細な説明（4000文字以内）

- [ ] **グラフィック アセット**
  - アイコン（512x512 PNG）
  - フィーチャー グラフィック（1024x500 PNG）
  - スクリーンショット（最低2枚）

- [ ] **分類**
  - アプリのカテゴリ
  - コンテンツのレーティング

- [ ] **連絡先情報**
  - メールアドレス
  - プライバシーポリシー URL（必須の場合）

- [ ] **価格と配布**
  - 無料/有料
  - 配布国
  - コンテンツガイドライン同意

---

## 🔧 トラブルシューティングコマンド集

### 署名確認
```bash
# APK署名確認
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk

# AAB署名確認（解凍して確認）
unzip -l build/app/outputs/bundle/release/app-release.aab
```

### パッケージ情報確認
```bash
# APKのパッケージ情報
$ANDROID_HOME/build-tools/35.0.0/aapt dump badging \
  build/app/outputs/flutter-apk/app-release.apk | grep -E "(package:|launchable-activity)"

# 出力例:
# package: name='com.penta.app' versionCode='1' versionName='1.0.0'
# launchable-activity: name='com.penta.app.MainActivity'
```

### Gradleデバッグ
```bash
# Gradle情報表示
cd android
./gradlew --version
./gradlew tasks

# ビルド詳細ログ
./gradlew bundleRelease --stacktrace --info
```

### Flutter環境確認
```bash
flutter doctor -v
flutter --version
flutter config --list
```

---

## 📚 重要な注意事項

### 🔐 セキュリティ

1. **キーストアファイルの保管**
   - `upload-keystore.jks` を安全な場所にバックアップ
   - パスワードを安全に記録
   - Gitにコミットしない

2. **パスワード管理**
   - 強力なパスワードを使用
   - パスワードマネージャーで管理
   - key.properties をGitから除外

### 🚨 よくある間違い

1. **キーを紛失する**
   - 紛失すると、アプリの更新が永久に不可能
   - 必ず安全な場所にバックアップ

2. **デバッグビルドをアップロード**
   - `--release` フラグを忘れない
   - 署名設定を確認

3. **パッケージ名の不一致**
   - build.gradle.kts と MainActivity で一致させる
   - AndroidManifest.xml も確認

4. **Gitにキーをコミット**
   - .gitignore に必ず追加
   - すでにコミットした場合は履歴から削除

### 📱 テスト推奨

1. **内部テスト配布**
   - App Bundleを内部テストトラックにアップロード
   - 実機でテスト

2. **複数デバイステスト**
   - 異なるAndroidバージョンでテスト
   - 画面サイズの違いを確認

3. **クリーンインストール**
   - アプリを完全削除してから再インストール
   - データの保存・復元を確認

---

## 🎓 学んだこと・ベストプラクティス

### 開発段階から準備すべきこと

1. **最初からカスタムパッケージ名を使用**
   - `flutter create --org com.yourcompany appname`
   - 後から変更するのは手間

2. **署名キーを早めに作成**
   - 開発初期にリリース署名を設定
   - テストビルドから本番と同じ署名を使用

3. **バージョン管理を計画的に**
   - pubspec.yaml でバージョンを管理
   - セマンティックバージョニングを採用

4. **ドキュメント作成を習慣化**
   - リリースノートを継続的に更新
   - トラブルシューティング情報を記録

### Flutter特有の注意点

1. **Kotlin DSL構文**
   - build.gradle → build.gradle.kts への移行
   - import文が必要（java.util.Properties など）

2. **パッケージ構造**
   - MainActivity のディレクトリ構造を正確に
   - package宣言とディレクトリ構造を一致させる

3. **ビルドキャッシュ**
   - flutter clean で完全リセット
   - Gradleキャッシュも考慮

---

## 📞 サポートリソース

### 公式ドキュメント

- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Android: Sign your app](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

### コミュニティ

- Flutter公式Discord
- Stack Overflow: [flutter]タグ
- GitHub Issues: flutter/flutter

---

## 🎉 成功の確認

以下がすべてクリアできていれば公開可能:

✅ `flutter build appbundle --release` が成功
✅ 署名確認でリリース証明書が表示される
✅ パッケージ名が com.example.* 以外
✅ Google Play Console にアップロード成功
✅ エラーメッセージが表示されない

---

**作成日**: 2024年11月
**対象バージョン**: Flutter 3.35.4, Android SDK 35
**アプリ例**: Penta v1.0.0

このドキュメントは実際のトラブルシューティング経験に基づいて作成されました。
