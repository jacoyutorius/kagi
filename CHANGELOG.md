# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-12-09

### Changed
- **BREAKING**: インターフェースを大幅に簡素化
  - Secret ID を直接引数として指定する方式に変更
  - `kagi import <secret-id>` / `kagi download <secret-id>`
- **BREAKING**: config.yml を廃止
  - 事前設定が不要に
  - 全ての設定をコマンドラインオプションで指定
- デフォルト値を設定
  - `--profile` のデフォルト: `default`
  - `--region` のデフォルト: `ap-northeast-1`

### Removed
- **BREAKING**: `kagi configure` コマンドを削除
- **BREAKING**: `kagi add` コマンドを削除
- **BREAKING**: `kagi list` コマンドを削除
- `lib/kagi/config.rb` モジュールを削除
- `ConfigError` クラスを削除

### Added
- v0.1.x からの移行ガイドを README に追加
- シェルエイリアスの活用例を README に追加

### Fixed
- JSON パースエラー時のエラーメッセージを改善
  - シークレットの実際の内容（先頭100文字）を表示
  - JSON 形式が必要であることを明示

## [0.1.0] - 2025-12-04

### Added
- 初回リリース
- AWS Secrets Manager からシークレットを取得
- dotenv 形式での `.env` ファイル生成
- export 形式での環境変数出力
- config.yml による設定管理
- `kagi configure` - 初期設定
- `kagi add` - プロジェクト/環境の追加
- `kagi download` - .env ファイル生成
- `kagi import` - export 文の出力
- `kagi list` - プロジェクト一覧表示
- `kagi version` - バージョン表示
- RSpec によるテスト
- GitHub Actions CI/CD

[0.2.0]: https://github.com/jacoyutorius/kagi/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jacoyutorius/kagi/releases/tag/v0.1.0
