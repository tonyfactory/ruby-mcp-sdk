# MCP Ruby SDK

A Ruby implementation of the Model Context Protocol (MCP), enabling Ruby applications to create servers and clients that expose capabilities to Large Language Models.

## Overview

The Model Context Protocol allows applications to provide context for LLMs in a standardized way, separating the concerns of providing context from the actual LLM interaction. This Ruby SDK implements the full MCP specification, making it easy to:

- Build MCP clients that can connect to any MCP server
- Create MCP servers that expose resources, prompts and tools
- Use standard transports like stdio and SSE
- Handle all MCP protocol messages and lifecycle events

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcp'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install mcp
```

## Quick Start

### Creating a Simple Server

Here's how to create a basic MCP server that exposes a calculator tool:

```ruby
# server.rb
require 'mcp/server/fastmcp'

# Create an MCP server
mcp = MCP::Server::FastMCP.new("Calculator")

# Add a tool
mcp.tool(:add) do |a, b|
  a + b
end

# Run the server
if __FILE__ == $0
  mcp.run
end
```

### Creating a Client

Here's how to create a client that connects to an MCP server:

```ruby
# client.rb
require 'mcp/client'
require 'mcp/client/stdio'

# Connect to a server
MCP::Client::Stdio.connect(['python', 'server.py']) do |client|
  # Initialize the connection
  client.initialize!

  # List available tools
  tools = client.list_tools
  puts "Available tools: #{tools.map(&:name).join(', ')}"

  # Call a tool
  result = client.call_tool('add', arguments: { a: 5, b: 3 })
  puts "5 + 3 = #{result}"
end
```

## Core Concepts

The MCP protocol defines three core primitives:

### Resources
Resources are read-only data sources exposed by servers. They can be static files or dynamic content:

```ruby
mcp.resource("config://app") do
  { environment: "production", version: "1.0.0" }.to_json
end

mcp.resource("users://{user_id}/profile") do |user_id|
  # Fetch and return user profile data
  User.find(user_id).profile.to_json
end
```

### Tools
Tools allow LLMs to perform actions through your server:

```ruby
mcp.tool(:send_email) do |to, subject, body|
  EmailService.send(to: to, subject: subject, body: body)
  "Email sent successfully"
end
```

### Prompts
Prompts are reusable templates for LLM interactions:

```ruby
mcp.prompt(:review_code) do |code|
  "Please review this code and provide feedback:\n\n#{code}"
end
```

## Advanced Features

### Context Support

Access server context in your handlers:

```ruby
mcp.tool(:long_task) do |files, context|
  files.each_with_index do |file, i|
    context.info("Processing #{file}")
    context.report_progress(i, files.length)
    # Process file...
  end
  "Processing complete"
end
```

### Async Support

All handlers can be async using Ruby's Fiber scheduler:

```ruby
mcp.tool(:fetch_data) do |url|
  response = Async::HTTP::Internet.new.get(url)
  response.read
end
```

## Examples

Check the `examples/` directory for complete examples:

- `calculator_server.rb` - A simple calculator server
- `echo_server.rb` - Echo server demonstrating all primitives
- `client_example.rb` - Client usage examples

## Documentation

For more information on the Model Context Protocol, see:

- [Model Context Protocol documentation](https://modelcontextprotocol.io)
- [Model Context Protocol specification](https://spec.modelcontextprotocol.io)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
