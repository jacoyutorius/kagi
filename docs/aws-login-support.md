# aws login 対応の技術解説

## 概要

Kagi v0.2.0 では、2025年11月に追加された `aws login` コマンドの認証情報に対応しました。
このドキュメントでは、実装時に直面した問題と解決策を解説します。

## aws login とは

`aws login` は AWS CLI v2.32.0 以降（2025年11月19日リリース）で利用できる新しい認証機能です:

- **ブラウザベース認証**: AWS Management Console にブラウザでログイン
- **一時的な認証情報**: 自動的に更新される短期間の認証情報を生成
- **OAuth 2.0 + PKCE**: セキュアな認証フロー
- **長期的なアクセスキー不要**: セキュリティリスクを削減

認証情報は `~/.aws/config` に以下の形式で保存されます:

```ini
[profile my-profile]
login_session = arn:aws:sts::123456789012:assumed-role/MyRole/user
region = ap-northeast-1
```

---

## 実装時の問題と解決策

### 問題1: `Aws::SharedCredentials` が `aws login` に非対応

#### 最初の実装

```ruby
# ~/.aws/credentials からプロファイルを読み込む
credentials = Aws::SharedCredentials.new(profile_name: "my-profile")

Aws::SecretsManager::Client.new(
  region: region,
  credentials: credentials
)
```

#### 問題点

- `Aws::SharedCredentials` は `~/.aws/credentials` ファイルからしか認証情報を読み込めない
- `aws login` は `~/.aws/config` の `login_session` に認証情報を保存する
- そのため `Aws::SharedCredentials.new` が `nil` を返す
- 結果: `undefined method 'access_key_id' for nil` エラー

#### エラーの再現

```bash
$ kagi import compal/dev --profile my-profile
エラー: 予期しないエラーが発生しました: undefined method 'access_key_id' for nil
```

---

### 問題2: `ENV['AWS_PROFILE']` の設定タイミング

#### 2回目の実装

```ruby
# 環境変数でプロファイルを指定
ENV['AWS_PROFILE'] = profile

Aws::SecretsManager::Client.new(
  region: region,
  credentials: nil
)
```

#### 問題点

- 環境変数を設定しても、既に Ruby プロセスが起動しているため反映されない
- AWS SDK が環境変数を読み込むのは初期化時のみ
- 結果: 認証情報が見つからない

#### エラーの再現

```bash
$ kagi import compal/dev --profile my-profile
エラー: AWS 認証情報が見つかりません。AWS Profile 'my-profile' を確認してください。
```

---

### 解決策: `profile` オプションを直接渡す

#### 最終的な実装

```ruby
def create_client(profile:, region:, debug: false)
  has_env_creds = ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
  
  if has_env_creds
    # 環境変数が設定されている場合は明示的に Credentials を作成
    credentials = Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY'],
      ENV['AWS_SESSION_TOKEN']
    )
    
    Aws::SecretsManager::Client.new(
      region: region,
      credentials: credentials
    )
  else
    # プロファイルを指定して AWS SDK のデフォルト認証情報チェーンに任せる
    Aws::SecretsManager::Client.new(
      region: region,
      profile: profile  # ← ここがポイント!
    )
  end
end
```

#### ポイント

1. **環境変数がある場合**: 明示的に `Aws::Credentials` を作成
2. **プロファイルを使う場合**: `profile: profile` オプションを渡して SDK に任せる
3. **credentials を指定しない**: SDK が自動的に適切な認証情報を見つける

---

## AWS SDK の認証情報チェーン

`profile: profile` オプションを渡すと、AWS SDK は以下の順序で認証情報を探します:

1. **環境変数**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`

2. **aws login のキャッシュ**
   - `~/.aws/config` の `login_session`

3. **aws sso login のキャッシュ**
   - `~/.aws/sso/cache/`

4. **~/.aws/credentials**
   - 指定されたプロファイルの認証情報

5. **IAM Role**
   - EC2/ECS などで実行時

この仕組みにより、全ての認証方式に対応できます。

---

## 対応状況の比較

| 実装方法 | 環境変数 | aws login | aws sso login | ~/.aws/credentials | IAM Role |
|---------|---------|-----------|---------------|-------------------|----------|
| `Aws::SharedCredentials` | ❌ | ❌ | ❌ | ✅ | ❌ |
| `ENV['AWS_PROFILE']` 設定 | ✅ | ⚠️ | ⚠️ | ⚠️ | ❌ |
| **`profile: profile` オプション** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 動作確認

### aws login で認証

```bash
# aws login でログイン
aws login

# Kagi で使用
kagi import my-secret --profile my-profile
```

### 環境変数で認証

```bash
# 環境変数を設定
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Kagi で使用（--profile 不要）
kagi import my-secret
```

### デバッグログで確認

```bash
# どの認証方式が使われているか確認
kagi import my-secret --profile my-profile --debug

# 出力例:
# DEBUG: AWS Profile 'my-profile' を使用します (AWS SDK のデフォルト認証情報チェーン)
```

---

## まとめ

- `Aws::SharedCredentials` は `~/.aws/credentials` 専用で、`aws login` には非対応
- `ENV['AWS_PROFILE']` の設定はタイミングの問題で動作しない
- **`profile: profile` オプション**を使うことで、AWS SDK のデフォルト認証情報チェーンが動作し、全ての認証方式に対応できる

この実装により、Kagi は以下の全ての認証方式をサポートします:

- ✅ 環境変数 (`AWS_ACCESS_KEY_ID` など)
- ✅ `aws login` (新しいブラウザベース認証)
- ✅ `aws sso login` (SSO 認証)
- ✅ `~/.aws/credentials` (従来のプロファイル)
- ✅ IAM Role (EC2/ECS などで実行時)
