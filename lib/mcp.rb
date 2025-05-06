# frozen_string_literal: true

require_relative 'mcp/version'
require_relative 'mcp/types'
require_relative 'mcp/server'
require_relative 'mcp/client'
require_relative 'mcp/transport/stdio'
require_relative 'mcp/server/fastmcp'
require_relative 'mcp/client/stdio'
require_relative 'mcp/client/misoca'

module MCP
  class Error < StandardError; end
end
