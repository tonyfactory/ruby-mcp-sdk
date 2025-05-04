#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/mcp/server/fastmcp"

# Create a calculator MCP server
mcp = MCP::Server::FastMCP.new("Calculator")

# Add basic arithmetic tools
mcp.tool(:add, description: "Add two numbers") do |a, b|
  a + b
end

mcp.tool(:subtract, description: "Subtract two numbers") do |a, b|
  a - b
end

mcp.tool(:multiply, description: "Multiply two numbers") do |a, b|
  a * b
end

mcp.tool(:divide, description: "Divide two numbers") do |a, b|
  raise "Division by zero" if b == 0
  a.to_f / b
end

# Add a resource for calculation history
@history = []

mcp.resource("history://recent", description: "Recent calculation history") do
  @history.last(10).to_json
end

# Add a prompt for complex calculations
mcp.prompt(:calculate, description: "Perform a complex calculation") do |expression|
  "Please calculate the following expression: #{expression}"
end

# Run the server
if __FILE__ == $0
  puts "Starting Calculator MCP Server..."
  mcp.run
end
