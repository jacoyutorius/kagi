# Kagi 🔑

AWS Secrets Manager から秘匿情報を取得して、ローカル開発環境向けの `.env` ファイルを生成する Ruby 製 CLI ツール。

## 特徴

- 🔐 **AWS Secrets Manager と統合** - 秘匿情報の一元管理
- 🚀 **シンプルなコマンド** - `kagi download` で `.env` を即座に生成
- 🎯 **柔軟な設定** - プロジェクト/環境ごとに AWS Profile/Region を管理
- 💎 **Ruby 製** - AWS SDK を直接使用 (AWS CLI 不要)
- 🔒 **安全** - `.env` ファイルを Git 管理せず、AWS IAM で権限制御

## インストール

```bash
gem install kagi
```

または Gemfile に追加:

```ruby
gem 'kagi'
```

## 使い方

### 1. 初期設定

```bash
kagi configure
```

対話式で AWS Profile と Region を設定します。設定は `~/.config/kagi/config.yml` に保存されます。

### 2. プロジェクト設定

`~/.config/kagi/config.yml` を編集して、プロジェクトと環境を追加します:

```yaml
defaults:
  profile: my-aws-profile
  region: ap-northeast-1

projects:
  myapp:
    dev:
      secret_id: kagi/myapp/dev
    stg:
      secret_id: kagi/myapp/stg
    prd:
      secret_id: kagi/myapp/prd
      profile: production-profile  # 特定環境のみ profile を上書き可能
```

**または、`kagi add` コマンドで追加:**

```bash
# 対話式で追加
kagi add myapp dev

# オプション指定で追加
kagi add myapp stg --secret-id kagi/myapp/stg
kagi add myapp prd --secret-id kagi/myapp/prd --profile production-profile
```

### 3. .env ファイルを生成

```bash
# 標準出力に表示
kagi download myapp dev

# ファイルに保存
kagi download myapp dev --path .env.development.local

# 既存ファイルを上書き
kagi download myapp dev --path .env --force
```

**設定なしで直接 Secret ID を指定:**

```bash
# --secret-id オプションで直接実行
kagi download --secret-id kagi/myapp/dev
kagi download --secret-id kagi/myapp/dev --path .env
```

### 4. 環境変数をエクスポート

```bash
# export 文を出力
kagi import myapp dev

# 現在のシェルに読み込む
eval "$(kagi import myapp dev)"
```

**設定なしで直接 Secret ID を指定:**

```bash
kagi import --secret-id kagi/myapp/dev
```

### 5. プロジェクト一覧を表示

```bash
kagi list
```

## コマンドリファレンス

### `kagi configure`

初期設定を行います。デフォルトの AWS Profile と Region を対話式で設定します。

### `kagi add <project> <env>`

プロジェクト/環境を設定に追加します。対話式またはオプション指定で追加できます。

**オプション:**
- `--secret-id SECRET_ID` - Secret ID を指定
- `--profile PROFILE` - AWS Profile を指定
- `--region REGION` - AWS Region を指定

**使用例:**
```bash
# 対話式
kagi add myapp dev

# オプション指定
kagi add myapp prd --secret-id kagi/myapp/prd --profile prod-profile
```

### `kagi download [project] [env]`

AWS Secrets Manager からシークレットを取得し、dotenv 形式で出力します。

**オプション:**
- `--secret-id SECRET_ID` - Secret ID を直接指定（この場合 project/env は不要）
- `--path PATH` - 出力先ファイルパス
- `--force` - 既存ファイルを上書き
- `--profile PROFILE` - AWS Profile を指定 (設定を上書き)
- `--region REGION` - AWS Region を指定 (設定を上書き)

**使用例:**
```bash
# 設定から取得
kagi download myapp dev

# Secret ID を直接指定
kagi download --secret-id kagi/myapp/dev --path .env
```

### `kagi import [project] [env]`

環境変数を export する形式で出力します。

**オプション:**
- `--secret-id SECRET_ID` - Secret ID を直接指定（この場合 project/env は不要）
- `--profile PROFILE` - AWS Profile を指定
- `--region REGION` - AWS Region を指定

**使用例:**
```bash
# 設定から取得
eval "$(kagi import myapp dev)"

# Secret ID を直接指定
eval "$(kagi import --secret-id kagi/myapp/dev)"
```

### `kagi list`

設定されているプロジェクト/環境の一覧を表示します。

### `kagi version`

バージョン情報を表示します。

## AWS Secrets Manager の設定

Secrets Manager では、1つの Secret に JSON 形式で環境変数を保存します:

**SecretId:** `kagi/myapp/dev`

**SecretString:**
```json
{
  "DATABASE_URL": "postgres://localhost/mydb",
  "API_KEY": "your-api-key",
  "RAILS_MASTER_KEY": "xxxx"
}
```

## AWS Profile/Region の優先順位

最終的に使用される AWS Profile/Region は以下の優先順位で決定されます:

1. CLI の `--profile` / `--region` オプション
2. `config.yml` の `projects.<name>.<env>.profile` / `region`
3. `config.yml` の `defaults.profile` / `region`
4. `"default"` / `"ap-northeast-1"`

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
      "Resource": "arn:aws:secretsmanager:*:*:secret:kagi/*"
    }
  ]
}
```

## 開発

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/kagi.git
cd kagi

# 依存関係のインストール
bundle install
```

### テストの実行

```bash
# 全テストを実行
bundle exec rspec

# 特定のテストファイルを実行
bundle exec rspec spec/kagi/config_spec.rb

# verbose モードで実行
bundle exec rspec --format documentation
```

### 開発時の動作確認

開発中は `bundle exec exe/kagi` でコマンドを実行できます。

#### 1. ヘルプの確認

```bash
bundle exec exe/kagi --help
bundle exec exe/kagi download --help
```

#### 2. テスト用の設定ファイルを作成

まず、テスト用の設定を作成します:

```bash
# configure コマンドで初期設定
bundle exec exe/kagi configure
```

または、手動で `~/.config/kagi/config.yml` を作成:

```yaml
defaults:
  profile: default
  region: ap-northeast-1

projects:
  testapp:
    dev:
      secret_id: kagi/testapp/dev
```

#### 3. AWS Secrets Manager にテストデータを作成

AWS CLI または AWS Console で、テスト用のシークレットを作成します:

```bash
aws secretsmanager create-secret \
  --name kagi/testapp/dev \
  --secret-string '{"DATABASE_URL":"postgres://localhost/testdb","API_KEY":"test-key-123"}' \
  --region ap-northeast-1 \
  --profile default
```

#### 4. コマンドの動作確認

```bash
# プロジェクト一覧を表示
bundle exec exe/kagi list

# 標準出力に表示
bundle exec exe/kagi download testapp dev

# ファイルに保存
bundle exec exe/kagi download testapp dev --path .env.test

# export 形式で出力
bundle exec exe/kagi import testapp dev

# バージョン確認
bundle exec exe/kagi version
```

#### 5. デバッグ

コードにデバッグポイントを追加する場合:

```ruby
# lib/kagi/cli.rb など
require 'debug'
binding.break  # ここでブレークポイント
```

実行時に対話的デバッガが起動します。

### Gem のビルドとインストール

```bash
# Gem をビルド
gem build kagi.gemspec

# ローカルにインストール
gem install kagi-0.1.0.gem

# インストール後は bundle exec なしで実行可能
kagi --help
kagi download testapp dev

# アンインストール
gem uninstall kagi
```

### コードスタイル

Ruby の標準的なスタイルガイドに従っています:

- インデント: 2スペース
- 文字列: ダブルクォート推奨
- `frozen_string_literal: true` を各ファイルの先頭に記載

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。

## 貢献

Issue や Pull Request を歓迎します!

## 作者

Yuto Ogi
