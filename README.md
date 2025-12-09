[![CI](https://github.com/jacoyutorius/kagi/actions/workflows/ci.yml/badge.svg)](https://github.com/jacoyutorius/kagi/actions/workflows/ci.yml)

# Kagi 🔑

AWS Secrets Manager から秘匿情報を取得して、ローカル開発環境向けの `.env` ファイルを生成する Ruby 製 CLI ツール。

## 特徴

- 🔐 **AWS Secrets Manager と統合** - 秘匿情報の一元管理
- 🚀 **シンプルなコマンド** - Secret ID を直接指定するだけ
- 💎 **Ruby 製** - AWS SDK を直接使用 (AWS CLI 不要)
- 🔒 **安全** - `.env` ファイルを Git 管理せず、AWS IAM で権限制御
- ⚡ **設定不要** - config.yml などの事前設定が不要

## インストール

```bash
gem install kagi
```

または Gemfile に追加:

```ruby
gem 'kagi'
```

## 使い方

### 基本的な使用方法

Secret ID を直接指定するだけで使えます:

```bash
# 環境変数を export 形式で出力
kagi import compal/dev

# .env ファイルを生成
kagi download compal/dev --path .env
```

### AWS Profile を指定

複数の AWS アカウントを使い分ける場合:

```bash
# AWS Profile を指定
kagi import compal/dev --profile compal_user

# Region も指定
kagi import compal/dev --profile compal_user --region us-east-1
```

### ファイルへの出力

```bash
# .env ファイルに保存
kagi download compal/dev --path .env

# 既存ファイルを上書き
kagi download compal/dev --path .env --force
```

### シェルに環境変数を読み込む

```bash
# 現在のシェルに環境変数を読み込む
eval "$(kagi import compal/dev)"
```

## コマンドリファレンス

### `kagi import <secret-id>`

環境変数を export する形式で出力します。

**引数:**
- `<secret-id>` - AWS Secrets Manager の Secret ID（必須）

**オプション:**
- `--profile PROFILE` - AWS Profile を指定（デフォルト: `default`）
- `--region REGION` - AWS Region を指定（デフォルト: `ap-northeast-1`）

**使用例:**
```bash
# 最小限の使用
kagi import compal/dev

# AWS Profile を指定
kagi import compal/dev --profile compal_user

# シェルに読み込む
eval "$(kagi import compal/dev)"
```

### `kagi download <secret-id>`

AWS Secrets Manager からシークレットを取得し、dotenv 形式で出力します。

**引数:**
- `<secret-id>` - AWS Secrets Manager の Secret ID（必須）

**オプション:**
- `--profile PROFILE` - AWS Profile を指定（デフォルト: `default`）
- `--region REGION` - AWS Region を指定（デフォルト: `ap-northeast-1`）
- `--path PATH` - 出力先ファイルパス
- `--force` - 既存ファイルを上書き

**使用例:**
```bash
# 標準出力に表示
kagi download compal/dev

# ファイルに保存
kagi download compal/dev --path .env

# AWS Profile を指定してファイルに保存
kagi download compal/dev --profile compal_user --path .env
```

### `kagi version`

バージョン情報を表示します。

```bash
kagi version
```

## AWS Secrets Manager の設定

Secrets Manager では、1つの Secret に JSON 形式で環境変数を保存します:

**SecretId:** `compal/dev`

**SecretString:**
```json
{
  "DATABASE_URL": "postgres://localhost/mydb",
  "API_KEY": "your-api-key",
  "RAILS_MASTER_KEY": "xxxx"
}
```

## 必要な IAM 権限

Kagi を使用するには、以下の IAM 権限が必要です:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:*"
    }
  ]
}
```

## シェルエイリアスの活用

頻繁に使う Secret ID はシェルのエイリアスに登録すると便利です:

```bash
# ~/.zshrc または ~/.bashrc
alias kagi-compal-dev='kagi import compal/dev --profile compal_user'
alias kagi-compal-stg='kagi import compal/stg --profile compal_user'
```

使用例:
```bash
# エイリアスで簡単に実行
eval "$(kagi-compal-dev)"
```

## v0.1.x からの移行ガイド

### 主な変更点

v0.2.0 では、よりシンプルで直感的なインターフェースに変更されました:

- ✅ **config.yml が不要に** - 事前設定なしで使用可能
- ✅ **Secret ID を直接指定** - プロジェクト/環境の抽象化を廃止
- ❌ **廃止されたコマンド**: `configure`, `add`, `list`

### 移行方法

**Before (v0.1.x):**
```bash
# 事前設定が必要
kagi add compal dev --secret-id compal/dev --profile compal_user
kagi import compal dev
```

**After (v0.2.0):**
```bash
# Secret ID を直接指定
kagi import compal/dev --profile compal_user
```

### config.yml の確認

v0.1.x で使用していた `~/.config/kagi/config.yml` から Secret ID を確認できます:

```yaml
# 旧 config.yml
projects:
  compal:
    dev:
      secret_id: compal/dev
      profile: compal_user
```

この場合、新しいコマンドは:
```bash
kagi import compal/dev --profile compal_user
```

## 開発

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/jacoyutorius/kagi.git
cd kagi

# 依存関係のインストール
bundle install
```

### テストの実行

```bash
# 全テストを実行
bundle exec rspec

# verbose モードで実行
bundle exec rspec --format documentation
```

### 開発時の動作確認

開発中は `bundle exec exe/kagi` でコマンドを実行できます:

```bash
# ヘルプの確認
bundle exec exe/kagi --help

# コマンドの実行
bundle exec exe/kagi import compal/dev

# バージョン確認
bundle exec exe/kagi version
```

### Gem のビルドとインストール

```bash
# Gem をビルド
gem build kagi.gemspec

# ローカルにインストール
gem install kagi-0.2.0.gem

# インストール後は bundle exec なしで実行可能
kagi import compal/dev

# アンインストール
gem uninstall kagi
```

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。

## 貢献

Issue や Pull Request を歓迎します!

## 作者

Yuto Ogi
