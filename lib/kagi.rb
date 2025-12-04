# frozen_string_literal: true

require_relative "kagi/version"
require_relative "kagi/config"
require_relative "kagi/secrets"
require_relative "kagi/env_formatter"
require_relative "kagi/cli"

module Kagi
  class Error < StandardError; end
  class ConfigError < Error; end
  class SecretsError < Error; end
end
