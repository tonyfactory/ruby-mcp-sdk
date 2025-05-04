#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/mcp/server/fastmcp"

# Create an echo MCP server
mcp = MCP::Server::FastMCP.new("Echo")

# Add an echo tool
mcp.tool(:echo, description: "Echo a message back") do |message|
  "Tool echo: #{message}"
end

# Add an echo resource
mcp.resource("echo://{message}", description: "Echo a message as a resource") do |message|
  "Resource echo: #{message}"
end

# Add an echo prompt
mcp.prompt(:echo, description: "Create an echo prompt") do |message|
  "Please process this message: #{message}"
end

# Run the server
if __FILE__ == $0
  puts "Starting Echo MCP Server..."
  mcp.run
end
