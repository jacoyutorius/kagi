# frozen_string_literal: true

require "thor"

module Kagi
  class CLI < Thor
    class_option :profile, type: :string, desc: "AWS Profile 名"
    class_option :region, type: :string, desc: "AWS Region"

    desc "configure", "初期設定を行う"
    def configure
      puts "Kagi の初期設定を開始します"
      puts

      # 既存の設定を読み込む
      config = Config.load

      # デフォルト値を取得
      current_profile = config.dig("defaults", "profile") || "default"
      current_region = config.dig("defaults", "region") || "ap-northeast-1"

      # ユーザー入力
      print "AWS profile (default: #{current_profile}): "
      profile = $stdin.gets.chomp
      profile = current_profile if profile.empty?

      print "AWS region  (default: #{current_region}): "
      region = $stdin.gets.chomp
      region = current_region if region.empty?

      # 設定を保存
      config["defaults"] ||= {}
      config["defaults"]["profile"] = profile
      config["defaults"]["region"] = region

      Config.save(config)

      puts
      puts "設定を保存しました: #{Config::CONFIG_PATH}"
    rescue => e
      error "設定の保存に失敗しました: #{e.message}"
    end

    desc "download PROJECT ENV", ".env ファイルを生成する"
    option :path, type: :string, desc: "出力先ファイルパス"
    option :force, type: :boolean, default: false, desc: "既存ファイルを上書きする"
    def download(project, env)
      config = Config.load
      
      # AWS Profile/Region を解決
      profile = Config.resolve_profile(config, project, env, options[:profile])
      region = Config.resolve_region(config, project, env, options[:region])
      secret_id = Config.get_secret_id(config, project, env)

      # シークレットを取得
      secrets = Secrets.fetch(secret_id, profile: profile, region: region)
      
      # dotenv 形式に変換
      env_content = EnvFormatter.to_env(secrets)

      # 出力
      if options[:path]
        output_to_file(env_content, options[:path], options[:force])
      else
        puts env_content
      end
    rescue ConfigError, SecretsError => e
      error e.message
    rescue => e
      error "予期しないエラーが発生しました: #{e.message}"
    end

    desc "import PROJECT ENV", "環境変数を export する形式で出力する"
    def import(project, env)
      config = Config.load
      
      # AWS Profile/Region を解決
      profile = Config.resolve_profile(config, project, env, options[:profile])
      region = Config.resolve_region(config, project, env, options[:region])
      secret_id = Config.get_secret_id(config, project, env)

      # シークレットを取得
      secrets = Secrets.fetch(secret_id, profile: profile, region: region)
      
      # export 形式に変換
      export_content = EnvFormatter.to_exports(secrets)

      puts export_content
    rescue ConfigError, SecretsError => e
      error e.message
    rescue => e
      error "予期しないエラーが発生しました: #{e.message}"
    end

    desc "list", "プロジェクト一覧を表示する"
    def list
      config = Config.load
      projects = Config.list_projects(config)

      if projects.empty?
        puts "プロジェクトが登録されていません"
        puts "config.yml にプロジェクトを追加してください: #{Config::CONFIG_PATH}"
        return
      end

      projects.each do |proj|
        puts "#{proj[:project]}.#{proj[:env]} (secret_id=#{proj[:secret_id]})"
      end
    rescue => e
      error "プロジェクト一覧の取得に失敗しました: #{e.message}"
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
