# frozen_string_literal: true

require "aws-sdk-secretsmanager"
require "json"

module Kagi
  module Secrets
    module_function

    # AWS Secrets Manager からシークレットを取得する
    def fetch(secret_id, profile:, region:)
      client = create_client(profile: profile, region: region)

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
    rescue JSON::ParserError
      raise SecretsError, "シークレットの JSON パースに失敗しました"
    end

    # AWS クライアントを作成する
    def create_client(profile:, region:)
      credentials = if profile == "default"
        # default の場合は明示的に credentials を指定しない
        # (環境変数や IAM Role を優先)
        nil
      else
        Aws::SharedCredentials.new(profile_name: profile)
      end

      Aws::SecretsManager::Client.new(
        region: region,
        credentials: credentials
      )
    end
  end
end
