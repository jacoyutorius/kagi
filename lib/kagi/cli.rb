# frozen_string_literal: true

require "thor"

module Kagi
  class CLI < Thor
    desc "import SECRET_ID", "環境変数を export する形式で出力する"
    option :profile, type: :string, desc: "AWS Profile", default: "default"
    option :region, type: :string, desc: "AWS Region", default: "ap-northeast-1"
    option :debug, type: :boolean, desc: "デバッグログを表示", default: false
    def import(secret_id)
      profile = options[:profile]
      region = options[:region]
      debug = options[:debug]
      
      # シークレットを取得
      secrets = Secrets.fetch(secret_id, profile: profile, region: region, debug: debug)
      
      # export 形式に変換
      export_content = EnvFormatter.to_exports(secrets)

      puts export_content
    rescue SecretsError => e
      error e.message
    rescue => e
      error "予期しないエラーが発生しました: #{e.message}"
    end

    desc "download SECRET_ID", ".env ファイルを生成する"
    option :profile, type: :string, desc: "AWS Profile", default: "default"
    option :region, type: :string, desc: "AWS Region", default: "ap-northeast-1"
    option :path, type: :string, desc: "出力先ファイルパス", required: true
    option :force, type: :boolean, default: false, desc: "既存ファイルを上書きする"
    option :debug, type: :boolean, desc: "デバッグログを表示", default: false
    def download(secret_id)
      profile = options[:profile]
      region = options[:region]
      debug = options[:debug]
      
      # シークレットを取得
      secrets = Secrets.fetch(secret_id, profile: profile, region: region, debug: debug)
      
      # dotenv 形式に変換
      env_content = EnvFormatter.to_env(secrets)

      # ファイルに出力
      output_to_file(env_content, options[:path], options[:force])
    rescue SecretsError => e
      error e.message
    rescue => e
      error "予期しないエラーが発生しました: #{e.message}"
    end

    desc "version", "バージョンを表示する"
    def version
      puts "Kagi version #{Kagi::VERSION}"
    end

    private

    # ファイルに出力する
    def output_to_file(content, path, force)
      if File.exist?(path) && !force
        error "ファイルが既に存在します: #{path}\n--force オプションを使用して上書きしてください"
        return
      end

      File.write(path, content)
      puts "ファイルを保存しました: #{path}"
    end

    # エラーメッセージを表示して終了
    def error(message)
      warn "エラー: #{message}"
      exit 1
    end
  end
end
