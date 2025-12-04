# frozen_string_literal: true

require "spec_helper"
require "kagi"

RSpec.describe Kagi::EnvFormatter do
  describe ".to_env" do
    it "Hash を dotenv 形式に変換する" do
      hash = {
        "DATABASE_URL" => "postgres://localhost/mydb",
        "API_KEY" => "secret123",
        "PORT" => "3000"
      }

      result = described_class.to_env(hash)

      expect(result).to eq(<<~ENV)
        DATABASE_URL=postgres://localhost/mydb
        API_KEY=secret123
        PORT=3000
      ENV
    end

    it "空のハッシュの場合は改行のみ返す" do
      result = described_class.to_env({})
      expect(result).to eq("\n")
    end
  end

  describe ".to_exports" do
    it "Hash を export 文に変換する" do
      hash = {
        "DATABASE_URL" => "postgres://localhost/mydb",
        "API_KEY" => "secret123"
      }

      result = described_class.to_exports(hash)

      expect(result).to eq(<<~EXPORTS)
        export DATABASE_URL='postgres://localhost/mydb'
        export API_KEY='secret123'
      EXPORTS
    end

    it "シングルクォートを含む値を正しくエスケープする" do
      hash = { "MESSAGE" => "It's a test" }

      result = described_class.to_exports(hash)

      expect(result).to eq("export MESSAGE='It'\"'\"'s a test'\n")
    end

    it "空のハッシュの場合は改行のみ返す" do
      result = described_class.to_exports({})
      expect(result).to eq("\n")
    end
  end

  describe ".escape_single_quotes" do
    it "シングルクォートをエスケープする" do
      result = described_class.escape_single_quotes("It's a test")
      expect(result).to eq("It'\"'\"'s a test")
    end

    it "複数のシングルクォートをエスケープする" do
      result = described_class.escape_single_quotes("'hello' 'world'")
      expect(result).to eq("'\"'\"'hello'\"'\"' '\"'\"'world'\"'\"'")
    end

    it "シングルクォートがない場合はそのまま返す" do
      result = described_class.escape_single_quotes("hello world")
      expect(result).to eq("hello world")
    end
  end
end
