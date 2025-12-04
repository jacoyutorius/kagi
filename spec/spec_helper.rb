# frozen_string_literal: true

RSpec.configure do |config|
  # rspec-expectations の設定
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks の設定
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # 共有コンテキストのメタデータの動作を有効化
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # 出力フォーマット
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
