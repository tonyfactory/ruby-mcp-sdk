# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module MCP
  class Error < StandardError; end
end

require_relative "mcp/version"
