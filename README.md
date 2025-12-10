[![CI](https://github.com/jacoyutorius/kagi/actions/workflows/ci.yml/badge.svg)](https://github.com/jacoyutorius/kagi/actions/workflows/ci.yml)

# Kagi 🔑

AWS Secrets Manager から秘匿情報を取得して、ローカル開発環境向けの `.env` ファイルを生成する CLI ツール。

## インストール

```bash
gem install kagi
```

## 使い方

### import と download の使い分け

Kagi には2つのメインコマンドがあります:

| コマンド | 用途 | 出力形式 | 使用例 |
|---------|------|---------|--------|
| `import` | シェルに環境変数を読み込む | `export KEY='value'` | `eval "$(kagi import ...)"` |
| `download` | .env ファイルを生成 | `KEY=value` | `kagi download ... --path .env` |

#### import の使い方

現在のシェルセッションに環境変数を読み込みたい場合に使用します:

```bash
# シェルに環境変数を読み込む
eval "$(kagi import myproject/dev)"

# 読み込まれた環境変数を確認
echo $DATABASE_URL
```

**ポイント:** `eval` を使って実行する必要があります。

#### download の使い方

`.env` ファイルとして保存したい場合に使用します:

```bash
# .env ファイルを生成
kagi download myproject/dev --path .env

# 既存ファイルを上書き
kagi download myproject/dev --path .env --force

# 標準出力に表示（ファイルに保存しない）
kagi download myproject/dev
```

---

### AWS 認証の設定

Kagi は以下の認証方式に対応しています:

#### 1. aws login を使う（推奨）

2025年11月に追加された新しいブラウザベース認証です:

```bash
# ブラウザでログイン
aws login

# Kagi を実行（--profile 不要）
eval "$(kagi import myproject/dev)"
```

**メリット:**
- ブラウザで簡単にログイン
- 一時的な認証情報で安全
- 長期的なアクセスキー不要

#### 2. AWS Profile を使う

複数の AWS アカウントを使い分ける場合:

**Step 1: AWS Profile を設定**

`~/.aws/config` と `~/.aws/credentials` を作成:

```bash
# ~/.aws/config
[profile myproject-dev]
region = ap-northeast-1

[profile myproject-prod]
region = ap-northeast-1
```

```bash
# ~/.aws/credentials
[myproject-dev]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

[myproject-prod]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
```

**Step 2: Kagi で Profile を指定**

```bash
# 開発環境
eval "$(kagi import myproject/dev --profile myproject-dev)"

# 本番環境
eval "$(kagi import myproject/prd --profile myproject-prod)"
```

#### 3. 環境変数を使う

一時的な認証情報（Session Token 付き）を使う場合:

```bash
# 環境変数を設定
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Kagi を実行（--profile 不要）
eval "$(kagi import myproject/dev)"
```

**ポイント:** 環境変数が設定されている場合は、自動的に優先されます。

---

### よくある使い方

#### パターン1: 開発環境で毎回使う

```bash
# シェルに環境変数を読み込む
eval "$(kagi import myproject/dev --profile myproject-dev)"

# アプリケーションを起動
rails server
```

#### パターン2: .env ファイルを生成して Git 管理しない

```bash
# .env ファイルを生成
kagi download myproject/dev --profile myproject-dev --path .env

# .gitignore に追加
echo ".env" >> .gitignore

# アプリケーションを起動（.env を自動読み込み）
npm run dev
```

#### パターン3: CI/CD で使う

```bash
# GitHub Actions などで環境変数を使用
export AWS_ACCESS_KEY_ID="${{ secrets.AWS_ACCESS_KEY_ID }}"
export AWS_SECRET_ACCESS_KEY="${{ secrets.AWS_SECRET_ACCESS_KEY }}"

# Kagi で .env を生成
kagi download myproject/prod --path .env
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
kagi import myproject/dev

# AWS Profile を指定
kagi import myproject/dev --profile myproject_user

# シェルに読み込む
eval "$(kagi import myproject/dev)"
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
kagi download myproject/dev

# ファイルに保存
kagi download myproject/dev --path .env

# AWS Profile を指定してファイルに保存
kagi download myproject/dev --profile myproject_user --path .env
```

### `kagi version`

バージョン情報を表示します。

```bash
kagi version
```

## AWS Secrets Manager の設定

Secrets Manager では、1つの Secret に JSON 形式で環境変数を保存します:

**SecretId:** `myproject/dev`

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

---

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
bundle exec exe/kagi import myproject/dev

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
kagi import myproject/dev

# アンインストール
gem uninstall kagi
```

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。

## 貢献

Issue や Pull Request を歓迎します!

## 作者

Yuto Ogi
