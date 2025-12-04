# frozen_string_literal: true

require "yaml"
require "fileutils"

module Kagi
  module Config
    CONFIG_DIR = File.join(Dir.home, ".config", "kagi")
    CONFIG_PATH = File.join(CONFIG_DIR, "config.yml")

    module_function

    # 設定ファイルを読み込む
    def load
      return {} unless File.exist?(CONFIG_PATH)

      YAML.load_file(CONFIG_PATH) || {}
    rescue Psych::SyntaxError => e
      raise ConfigError, "設定ファイルの読み込みに失敗しました: #{e.message}"
    end

    # 設定ファイルを保存する
    def save(config)
      FileUtils.mkdir_p(CONFIG_DIR)
      File.write(CONFIG_PATH, YAML.dump(config))
    end

    # AWS Profile を優先順位に従って解決する
    # 優先順位: CLI オプション > project/env.profile > defaults.profile > "default"
    def resolve_profile(config, project, env, cli_profile = nil)
      return cli_profile if cli_profile

      project_config = config.dig("projects", project, env)
      return project_config["profile"] if project_config&.key?("profile")

      config.dig("defaults", "profile") || "default"
    end

    # AWS Region を優先順位に従って解決する
    def resolve_region(config, project, env, cli_region = nil)
      return cli_region if cli_region

      project_config = config.dig("projects", project, env)
      return project_config["region"] if project_config&.key?("region")

      config.dig("defaults", "region") || "ap-northeast-1"
    end

    # プロジェクト/環境の SecretId を取得する
    def get_secret_id(config, project, env)
      secret_id = config.dig("projects", project, env, "secret_id")
      raise ConfigError, "SecretId が見つかりません: #{project}.#{env}" unless secret_id

      secret_id
    end

    # プロジェクト一覧を取得する
    def list_projects(config)
      projects = config["projects"] || {}
      result = []

      projects.each do |project_name, envs|
        envs.each do |env_name, env_config|
          result << {
            project: project_name,
            env: env_name,
            secret_id: env_config["secret_id"],
            profile: env_config["profile"],
            region: env_config["region"]
          }
        end
      end

      result
    end
  end
end
