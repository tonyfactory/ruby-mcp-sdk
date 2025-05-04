#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/mcp/client/stdio"

# Connect to the calculator server
MCP::Client::Stdio.connect(["ruby", File.join(__dir__, "calculator_server.rb")]) do |client|
  # Initialize the connection
  puts "Initializing connection..."
  client.initialize!
  
  # List available tools
  puts "\nAvailable tools:"
  tools = client.list_tools
  tools.each do |tool|
    puts "  - #{tool.name}: #{tool.description}"
  end
  
  # Call some tools
  puts "\nCalculating 5 + 3..."
  result = client.call_tool("add", arguments: { a: 5, b: 3 })
  puts "Result: #{result}"
  
  puts "\nCalculating 10 * 4..."
  result = client.call_tool("multiply", arguments: { a: 10, b: 4 })
  puts "Result: #{result}"
  
  # List resources
  puts "\nAvailable resources:"
  resources = client.list_resources
  resources.each do |resource|
    puts "  - #{resource.uri}: #{resource.description}"
  end
  
  # Get a prompt
  puts "\nGetting calculation prompt..."
  prompt = client.get_prompt("calculate", arguments: { expression: "2 * (3 + 4)" })
  puts "Prompt: #{prompt}"
end

puts "\nClient example completed!"
