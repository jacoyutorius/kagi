# frozen_string_literal: true

require "spec_helper"
require "kagi"
require "tmpdir"
require "fileutils"

RSpec.describe Kagi::Config do
  let(:test_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(test_dir, "config.yml") }

  before do
    stub_const("Kagi::Config::CONFIG_DIR", test_dir)
    stub_const("Kagi::Config::CONFIG_PATH", config_path)
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe ".load" do
    context "設定ファイルが存在しない場合" do
      it "空のハッシュを返す" do
        expect(described_class.load).to eq({})
      end
    end

    context "設定ファイルが存在する場合" do
      it "設定を読み込む" do
        config = {
          "defaults" => {
            "profile" => "test-profile",
            "region" => "us-west-2"
          }
        }
        described_class.save(config)

        expect(described_class.load).to eq(config)
      end
    end
  end

  describe ".save" do
    it "設定ファイルを保存する" do
      config = {
        "defaults" => {
          "profile" => "my-profile",
          "region" => "ap-northeast-1"
        }
      }

      described_class.save(config)

      expect(File.exist?(config_path)).to be true
      loaded = described_class.load
      expect(loaded).to eq(config)
    end
  end

  describe ".resolve_profile" do
    let(:config) do
      {
        "defaults" => { "profile" => "default-profile" },
        "projects" => {
          "myapp" => {
            "dev" => {
              "secret_id" => "kagi/myapp/dev",
              "profile" => "dev-profile"
            },
            "prd" => {
              "secret_id" => "kagi/myapp/prd"
            }
          }
        }
      }
    end

    it "CLI オプションが最優先" do
      result = described_class.resolve_profile(config, "myapp", "dev", "cli-profile")
      expect(result).to eq("cli-profile")
    end

    it "プロジェクト設定が次に優先" do
      result = described_class.resolve_profile(config, "myapp", "dev")
      expect(result).to eq("dev-profile")
    end

    it "デフォルト設定が次に優先" do
      result = described_class.resolve_profile(config, "myapp", "prd")
      expect(result).to eq("default-profile")
    end

    it "何も設定されていない場合は 'default' を返す" do
      result = described_class.resolve_profile({}, "myapp", "dev")
      expect(result).to eq("default")
    end
  end

  describe ".resolve_region" do
    let(:config) do
      {
        "defaults" => { "region" => "us-east-1" },
        "projects" => {
          "myapp" => {
            "dev" => {
              "secret_id" => "kagi/myapp/dev",
              "region" => "ap-northeast-1"
            }
          }
        }
      }
    end

    it "CLI オプションが最優先" do
      result = described_class.resolve_region(config, "myapp", "dev", "us-west-2")
      expect(result).to eq("us-west-2")
    end

    it "プロジェクト設定が次に優先" do
      result = described_class.resolve_region(config, "myapp", "dev")
      expect(result).to eq("ap-northeast-1")
    end

    it "デフォルト設定が次に優先" do
      result = described_class.resolve_region(config, "myapp", "prd")
      expect(result).to eq("us-east-1")
    end

    it "何も設定されていない場合は 'ap-northeast-1' を返す" do
      result = described_class.resolve_region({}, "myapp", "dev")
      expect(result).to eq("ap-northeast-1")
    end
  end

  describe ".get_secret_id" do
    let(:config) do
      {
        "projects" => {
          "myapp" => {
            "dev" => { "secret_id" => "kagi/myapp/dev" }
          }
        }
      }
    end

    it "SecretId を返す" do
      result = described_class.get_secret_id(config, "myapp", "dev")
      expect(result).to eq("kagi/myapp/dev")
    end

    it "SecretId が見つからない場合はエラーを発生させる" do
      expect {
        described_class.get_secret_id(config, "myapp", "prd")
      }.to raise_error(Kagi::ConfigError, /SecretId が見つかりません/)
    end
  end

  describe ".list_projects" do
    let(:config) do
      {
        "projects" => {
          "app1" => {
            "dev" => { "secret_id" => "kagi/app1/dev" },
            "prd" => { "secret_id" => "kagi/app1/prd", "profile" => "prd-profile" }
          },
          "app2" => {
            "stg" => { "secret_id" => "kagi/app2/stg" }
          }
        }
      }
    end

    it "プロジェクト一覧を返す" do
      result = described_class.list_projects(config)

      expect(result).to contain_exactly(
        { project: "app1", env: "dev", secret_id: "kagi/app1/dev", profile: nil, region: nil },
        { project: "app1", env: "prd", secret_id: "kagi/app1/prd", profile: "prd-profile", region: nil },
        { project: "app2", env: "stg", secret_id: "kagi/app2/stg", profile: nil, region: nil }
      )
    end

    it "プロジェクトが空の場合は空配列を返す" do
      result = described_class.list_projects({})
      expect(result).to eq([])
    end
  end

  describe ".add_project" do
    it "プロジェクト/環境を追加する" do
      config = {}
      
      result = described_class.add_project(config, "myapp", "dev", secret_id: "kagi/myapp/dev")
      
      expect(result["projects"]["myapp"]["dev"]["secret_id"]).to eq("kagi/myapp/dev")
      expect(result["projects"]["myapp"]["dev"]["profile"]).to be_nil
      expect(result["projects"]["myapp"]["dev"]["region"]).to be_nil
    end

    it "profile と region を指定して追加する" do
      config = {}
      
      result = described_class.add_project(
        config, "myapp", "prd", 
        secret_id: "kagi/myapp/prd",
        profile: "prod-profile",
        region: "us-east-1"
      )
      
      expect(result["projects"]["myapp"]["prd"]["secret_id"]).to eq("kagi/myapp/prd")
      expect(result["projects"]["myapp"]["prd"]["profile"]).to eq("prod-profile")
      expect(result["projects"]["myapp"]["prd"]["region"]).to eq("us-east-1")
    end

    it "既存のプロジェクトに新しい環境を追加する" do
      config = {
        "projects" => {
          "myapp" => {
            "dev" => { "secret_id" => "kagi/myapp/dev" }
          }
        }
      }
      
      result = described_class.add_project(config, "myapp", "stg", secret_id: "kagi/myapp/stg")
      
      expect(result["projects"]["myapp"]["dev"]["secret_id"]).to eq("kagi/myapp/dev")
      expect(result["projects"]["myapp"]["stg"]["secret_id"]).to eq("kagi/myapp/stg")
    end
  end
end
