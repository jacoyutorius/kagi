# Kagi インターフェース簡素化 要件定義

## 概要

現在の Kagi は `config.yml` でプロジェクト/環境を管理する設計だが、よりシンプルで直感的なインターフェースに変更する。

## 現在の問題点

- `config.yml` の手動編集または `kagi add` コマンドでの事前設定が必要
- プロジェクト/環境という抽象化が必要以上に複雑
- Secret ID を直接指定できない（`--secret-id` オプションはあるが、メインの使い方ではない）

## 新しい設計

### 基本コンセプト

**Secret ID を直接引数として受け取る**シンプルな設計に変更する。

### コマンドインターフェース

#### Before (現在)
```bash
# 事前設定が必要
kagi add compal dev --secret-id compal/dev
kagi import compal dev

# または --secret-id オプション
kagi import --secret-id compal/dev
```

#### After (新設計)
```bash
# Secret ID を直接引数として指定
kagi import compal/dev

# AWS Profile を指定
kagi import compal/dev --profile compal_user

# デフォルト profile を使用
kagi import compal/dev  # --profile 未指定 = default
```

---

## 詳細仕様

### 1. config.yml の廃止

- `~/.config/kagi/config.yml` は使用しない
- プロジェクト/環境の概念を廃止
- 全ての設定をコマンドラインオプションで指定

### 2. コマンド引数

#### `kagi import <secret-id>`

**引数:**
- `<secret-id>` - AWS Secrets Manager の Secret ID（必須）
  - 例: `compal/dev`, `kagi/myapp/stg`, `crs/prd/app`

**オプション:**
- `--profile PROFILE` - AWS Profile を指定（任意）
  - 未指定の場合は `default` を使用
- `--region REGION` - AWS Region を指定（任意）
  - 未指定の場合は `ap-northeast-1` を使用

**使用例:**
```bash
# 最小限の使用
kagi import compal/dev

# AWS Profile を指定
kagi import compal/dev --profile compal_user

# Region も指定
kagi import compal/dev --profile compal_user --region us-east-1
```

#### `kagi download <secret-id>`

`import` と同様のインターフェース。

**追加オプション:**
- `--path PATH` - 出力先ファイルパス
- `--force` - 既存ファイルを上書き

**使用例:**
```bash
# 標準出力
kagi download compal/dev

# ファイルに保存
kagi download compal/dev --path .env

# AWS Profile を指定してファイルに保存
kagi download compal/dev --profile compal_user --path .env
```

### 3. 廃止するコマンド

以下のコマンドは不要になるため廃止:
- `kagi configure` - デフォルト設定が不要に
- `kagi add` - 事前設定が不要に
- `kagi list` - プロジェクト一覧の概念が不要に

### 4. 残すコマンド

- `kagi import <secret-id>` - メインコマンド
- `kagi download <secret-id>` - メインコマンド
- `kagi version` - バージョン表示

---

## 実装方針

### 変更が必要なファイル

1. **lib/kagi/cli.rb**
   - `import` コマンドの引数を `<secret-id>` に変更
   - `download` コマンドの引数を `<secret-id>` に変更
   - `configure`, `add`, `list` コマンドを削除

2. **lib/kagi/config.rb**
   - ファイル全体を削除（不要）

3. **spec/kagi/config_spec.rb**
   - ファイル全体を削除（不要）

4. **spec/kagi/cli_spec.rb**
   - 新しいインターフェースのテストを追加（必要に応じて）

5. **README.md**
   - 使用方法を全面的に書き換え

6. **kagi_spec_ja.md**
   - 仕様書を更新

### デフォルト値

- **AWS Profile**: `default`
- **AWS Region**: `ap-northeast-1`

### エラーハンドリング

- Secret ID が指定されていない場合: エラーメッセージを表示
- AWS Profile が存在しない場合: AWS SDK のエラーをそのまま表示
- Secret が見つからない場合: 既存のエラーメッセージを表示

---

## メリット

1. **シンプル** - config.yml の管理が不要
2. **直感的** - Secret ID を直接指定できる
3. **柔軟** - コマンドごとに異なる Profile/Region を指定可能
4. **学習コスト低** - 覚えるコマンドが少ない

## デメリットと対策

### デメリット1: Secret ID を毎回入力する必要がある

**対策:**
- シェルのエイリアスや関数で対応
  ```bash
  alias kagi-compal-dev='kagi import compal/dev --profile compal_user'
  ```
- 頻繁に使う Secret ID はドキュメントに記載

### デメリット2: プロジェクト一覧が見れない

**対策:**
- AWS CLI で確認可能
  ```bash
  aws secretsmanager list-secrets --profile compal_user
  ```
- 必要であれば README に記載

---

## 移行ガイド

### 既存ユーザー向け

**Before:**
```bash
kagi add compal dev --secret-id compal/dev --profile compal_user
kagi import compal dev
```

**After:**
```bash
kagi import compal/dev --profile compal_user
```

### config.yml の移行

既存の `config.yml` は使用されなくなるため、各プロジェクトの Secret ID を確認しておく。

```yaml
# 旧 config.yml
projects:
  compal:
    dev:
      secret_id: compal/dev
      profile: compal_user
```

↓

```bash
# 新しいコマンド
kagi import compal/dev --profile compal_user
```

---

## 実装スケジュール

1. **Phase 1**: CLI インターフェースの変更
2. **Phase 2**: Config モジュールの削除
3. **Phase 3**: テストの更新
4. **Phase 4**: ドキュメントの更新
5. **Phase 5**: 動作確認とリリース
