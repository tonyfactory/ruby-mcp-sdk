# frozen_string_literal: true

require 'test_helper'

class MCP::FastMCPTest < Minitest::Test
  def setup
    @server = MCP::FastMCP.new('FastMCPTest')
  end

  def test_server_name_and_version
    assert_equal 'FastMCPTest', @server.name
    assert_equal '1.0.0', @server.version
  end

  def test_tool_registration
    @server.tool(:echo, description: 'Echo back the input') do |input|
      input
    end

    response = @server.process_message({
                                         method: 'tools/list',
                                         id: 1
                                       })

    tools = response[:result][:tools]

    assert_equal 1, tools.length
    assert_equal 'echo', tools[0][:name]

    response = @server.process_message({
                                         method: 'tools/call',
                                         id: 2,
                                         params: {
                                           name: 'echo',
                                           arguments: { input: 'Hello, World!' }
                                         }
                                       })

    assert_equal 'Hello, World!', response[:result][:content][0][:text]
  end

  def test_resource_registration
    @server.resource('static://greeting', description: 'A static greeting') do
      'Hello from FastMCP!'
    end

    response = @server.process_message({
                                         method: 'resources/read',
                                         id: 3,
                                         params: { uri: 'static://greeting' }
                                       })

    assert_equal 'Hello from FastMCP!', response[:result][:contents][0][:text]
  end

  def test_prompt_registration
    @server.prompt(:review, description: 'Code review prompt') do |code|
      "Please review this code:\n\n#{code}"
    end

    response = @server.process_message({
                                         method: 'prompts/get',
                                         id: 4,
                                         params: {
                                           name: 'review',
                                           arguments: { code: "def hello; puts 'Hello'; end" }
                                         }
                                       })

    result = response[:result][:messages][0][:content][:text]

    assert_match(/Please review this code/, result)
    assert_match(/def hello; puts 'Hello'; end/, result)
  end
end
