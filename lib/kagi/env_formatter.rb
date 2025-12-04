# frozen_string_literal: true

module Kagi
  module EnvFormatter
    module_function

    # Hash を dotenv 形式に変換する
    # 例: { "KEY" => "value" } => "KEY=value\n"
    def to_env(hash)
      hash.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n"
    end

    # Hash を export 文に変換する
    # 例: { "KEY" => "value" } => "export KEY='value'\n"
    # シングルクォート内のシングルクォートは '\''  でエスケープ
    def to_exports(hash)
      hash.map do |k, v|
        escaped = escape_single_quotes(v.to_s)
        "export #{k}='#{escaped}'"
      end.join("\n") + "\n"
    end

    # シングルクォートをエスケープする
    # 'value' => 'value'\''s' (シングルクォートを閉じて、エスケープされたシングルクォートを追加し、再度開く)
    def escape_single_quotes(str)
      str.gsub("'", "'\"'\"'")
    end
  end
end
