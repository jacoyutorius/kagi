# frozen_string_literal: true

require_relative "lib/kagi/version"

Gem::Specification.new do |spec|
  spec.name = "kagi"
  spec.version = Kagi::VERSION
  spec.authors = ["Yuto Ogi"]
  spec.email = ["yuto.ogi@example.com"]

  spec.summary = "AWS Secrets Manager から .env ファイルを生成する CLI ツール"
  spec.description = "AWS Secrets Manager に保存された秘匿情報を取得し、ローカル開発環境向けの .env ファイルを生成する Ruby 製 CLI ツール"
  spec.homepage = "https://github.com/yourusername/kagi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Gem のファイルを指定
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    exe/*
    *.gemspec
    LICENSE
    README.md
  ])
  spec.bindir = "exe"
  spec.executables = ["kagi"]
  spec.require_paths = ["lib"]

  # 依存関係
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "aws-sdk-secretsmanager", "~> 1.0"

  # 開発依存
  spec.add_development_dependency "rspec", "~> 3.12"
end
