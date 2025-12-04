
# Kagi 仕様書（Draft v3・日本語版）

## 📘 概要

**Kagi** は、AWS Secrets Manager に保存された秘匿情報（APIキー、環境変数など）を安全に取得し、  
ローカル開発環境向けの **.env ファイル（dotenv形式）を生成するための Ruby 製 CLI ツール** です。

Rails / Next.js / Python / Go / Node.js など、あらゆるアプリケーションの開発環境セットアップを  
「コマンド一発」で統一できることを目的としています。

---

# 🎯 目的（Goals）

- チームメンバーが共通の `.env` を簡単に生成できる  
- 秘匿情報の唯一の情報源を AWS Secrets Manager に統一する  
- AWS IAM + Profile によりユーザーごとのアクセス制御が可能  
- CLI は Ruby 製、AWS SDK を利用（AWS CLI 非依存）  
- `.env` を直接生成 → eval magic（`eval "$(kagi import ...)"`）を避ける設計  
- OSS として公開可能な設計  

---

# 🔐 シークレット構造（AWS Secrets Manager）

Secrets Manager 側では **1 Secret = 1 Project/Environment** とする。

例：SecretId: `kagi/compal/dev`

```json
{
  "RAILS_ENV": "development",
  "DATABASE_URL": "postgres://...",
  "API_KEY": "xxxx",
  "NEXT_PUBLIC_API_URL": "https://dev.example.com"
}
```

Kagi は SecretString を JSON として読み込み、dotenv形式に変換する。

---

# 🧩 設定ファイル（config.yml）

Kagi の設定ファイルはユーザー単位で保持し、  
XDG Base Directory に倣い次の場所に保存する：

```
~/.config/kagi/config.yml
```

### config.yml の例

```yaml
defaults:
  profile: crassone-dev
  region: ap-northeast-1

projects:
  compal:
    dev:
      secret_id: kagi/compal/dev
    stg:
      secret_id: kagi/compal/stg
    prd:
      secret_id: kagi/compal/prd
```

### 設定の役割

| 項目 | 説明 |
|------|------|
| defaults.profile | AWS SDK に渡す default の AWS profile |
| defaults.region | default の AWS region |
| projects.<name>.<env>.secret_id | Secrets Manager の SecretId |
| projects.<name>.<env>.profile | 特定 env のみ profile を上書き（任意） |

---

# 🌐 AWS Profile の優先順位

最終的に利用される AWS Profile は次の順で決定する：

```
(最優先) CLI の --profile オプション
↓
config.yml の project/env.profile
↓
config.yml の defaults.profile
↓
"default"
```

region も同様に優先順位を適用する。

---

# 💻 CLI コマンド仕様

## 1. `kagi configure`
初期設定。  
デフォルトの AWS profile / region を対話式で設定する。

```
$ kagi configure
AWS profile (default: default): crassone-dev
AWS region  (default: ap-northeast-1): ap-northeast-1
Saved config to ~/.config/kagi/config.yml
```

---

## 2. `kagi download <project> <env>`
Secrets Manager のデータを dotenv形式で出力する（**推奨のメイン機能**）。

### 標準出力に出す
```
$ kagi download compal dev
DATABASE_URL=postgres://...
RAILS_MASTER_KEY=xxxx
NEXT_PUBLIC_API_URL=https://dev.example.com
```

### ファイルとして書き出す
```
$ kagi download compal dev --path .env.development.local
```

### 上書き
```
$ kagi download compal dev --path .env --force
```

---

## 3. `kagi import <project> <env>`
環境変数をエクスポートするための **export文** を出力する。

```
$ kagi import compal dev
export DATABASE_URL='postgres://...'
export RAILLS_MASTER_KEY='xxxx'
```

必要なら：

```
eval "$(kagi import compal dev)"
```

---

## 4. `kagi list`
config.yml の project/env の一覧を表示する。

```
$ kagi list
compal.dev (secret_id=kagi/compal/dev)
compal.prd (secret_id=kagi/compal/prd)
```

---

# 🏗 ディレクトリ構成（Gem 標準構成）

```
kagi/
  ├── exe/
  │     └── kagi               # CLIエントリ
  ├── lib/
  │     ├── kagi.rb
  │     ├── kagi/
  │     │     ├── cli.rb       # Thorベースの CLI 実装
  │     │     ├── config.rb    # config.yml 読み書き
  │     │     ├── secrets.rb   # AWS SDK によるフェッチ
  │     │     └── env_formatter.rb
  │     └── kagi/version.rb
  ├── spec/                    # RSpec
  └── kagi.gemspec
```

---

# 🧪 サンプル実装

## lib/kagi/secrets.rb（AWS SDK使用）

```ruby
require "aws-sdk-secretsmanager"
require "json"

module Kagi
  module Secrets
    module_function

    def fetch(secret_id, profile:, region:)
      client = Aws::SecretsManager::Client.new(
        region: region,
        credentials: Aws::SharedCredentials.new(profile_name: profile)
      )

      resp = client.get_secret_value(secret_id: secret_id)
      JSON.parse(resp.secret_string)
    rescue Aws::SecretsManager::Errors::ServiceError => e
      raise "SecretsManager error: #{e.message}"
    end
  end
end
```

---

## lib/kagi/env_formatter.rb

```ruby
module Kagi
  module EnvFormatter
    module_function

    def to_env(hash)
      hash.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n"
    end

    def to_exports(hash)
      hash.map do |k, v|
        escaped = v.to_s.gsub("'", %q('"'"'"'))
        "export #{k}='#{escaped}'"
      end.join("\n") + "\n"
    end
  end
end
```

---

# ⚙️ セキュリティ仕様

✔ `.env` ファイルは Git 管理しない  
✔ config.yml にシークレット本体は保存しない  
✔ Secrets Manager に必要な IAM 権限は最小限：

```
secretsmanager:GetSecretValue
```

✔ Kagi 自体は AWS CLI を利用せず AWS SDK を利用する  
→ 外部依存が減り安全・高速になる  

---

# 📈 今後の拡張（Future Enhancements）

- `kagi push`: ローカル .env を Secrets Manager にアップロード  
- `kagi diff`: ローカルとAWSの差分比較  
- `kagi edit`: $EDITOR で Secret を編集  
- `kagi rotate`: ランダムキー生成対応  
- `kagi generate`: 雛形 .env 作成コマンド  

---

# ✔ まとめ

この仕様により、Kagi は：

- AWS Secrets Manager を情報源として一元化  
- CLIから簡単に .env が生成できる  
- シンプルで Ruby らしい設計  
- チーム内で安全に共有可能  
- OSS としても拡張性・保守性が高い  

という強力なツールになります。

