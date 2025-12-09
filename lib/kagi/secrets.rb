# frozen_string_literal: true

require "aws-sdk-secretsmanager"
require "json"

module Kagi
  module Secrets
    module_function

    # AWS Secrets Manager からシークレットを取得する
    def fetch(secret_id, profile:, region:, debug: false)
      client = create_client(profile: profile, region: region, debug: debug)

      resp = client.get_secret_value(secret_id: secret_id)
      JSON.parse(resp.secret_string)
    rescue Aws::SecretsManager::Errors::ResourceNotFoundException
      raise SecretsError, "シークレットが見つかりません: #{secret_id}"
    rescue Aws::SecretsManager::Errors::InvalidRequestException => e
      raise SecretsError, "無効なリクエストです: #{e.message}"
    rescue Aws::SecretsManager::Errors::InvalidParameterException => e
      raise SecretsError, "無効なパラメータです: #{e.message}"
    rescue Aws::Errors::MissingCredentialsError
      raise SecretsError, "AWS 認証情報が見つかりません。AWS Profile '#{profile}' を確認してください。"
    rescue Aws::SecretsManager::Errors::ServiceError => e
      raise SecretsError, "AWS Secrets Manager エラー: #{e.message}"
    rescue JSON::ParserError => e
      # デバッグ用に実際のシークレット内容を表示（先頭100文字のみ）
      preview = resp.secret_string[0..100]
      raise SecretsError, "シークレットの JSON パースに失敗しました。\n" \
                          "シークレットは JSON 形式である必要があります。\n" \
                          "実際の内容（先頭100文字）: #{preview.inspect}\n" \
                          "パースエラー: #{e.message}"
    end

    # AWS クライアントを作成する
    def create_client(profile:, region:, debug: false)
      # デバッグ: 環境変数の状態を確認
      has_env_creds = ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      
      # 認証方法を判定
      if has_env_creds
        $stderr.puts "DEBUG: 環境変数から認証情報を使用します" if debug
        # 環境変数から明示的に認証情報を作成（Session Token にも対応）
        credentials = Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY_ID'],
          ENV['AWS_SECRET_ACCESS_KEY'],
          ENV['AWS_SESSION_TOKEN']  # Session Token がない場合は nil になる
        )
        
        Aws::SecretsManager::Client.new(
          region: region,
          credentials: credentials
        )
      else
        # プロファイルを指定して AWS SDK のデフォルト認証情報チェーンに任せる
        # これで aws login, aws sso login, ~/.aws/credentials の全てに対応
        $stderr.puts "DEBUG: AWS Profile '#{profile}' を使用します (AWS SDK のデフォルト認証情報チェーン)" if debug
        
        # profile オプションを渡して Client を作成
        # これで AWS SDK が自動的に適切な認証情報を見つける
        Aws::SecretsManager::Client.new(
          region: region,
          profile: profile
        )
      end
    end
  end
end
