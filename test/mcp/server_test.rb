# frozen_string_literal: true

require 'test_helper'

class MCP::ServerTest < Minitest::Test
  def setup
    @server = MCP::Server.new(name: 'TestServer', version: '1.0.0')
  end

  def test_server_initialization
    assert_equal 'TestServer', @server.name
    assert_equal '1.0.0', @server.version
    assert_instance_of MCP::Types::ServerCapabilities, @server.capabilities
  end

  def test_handle_initialize_request
    response = @server.process_message({
                                         method: 'initialize',
                                         id: 1,
                                         params: {
                                           protocolVersion: '2024-11-05',
                                           capabilities: {},
                                           clientInfo: {
                                             name: 'TestClient',
                                             version: '1.0.0'
                                           }
                                         }
                                       })

    assert_equal '2.0', response[:jsonrpc]
    assert_equal 1, response[:id]
    assert_equal '2024-11-05', response[:result][:protocolVersion]
    assert_equal 'TestServer', response[:result][:serverInfo][:name]
    assert_equal '1.0.0', response[:result][:serverInfo][:version]
  end

  def test_tool_registration_and_execution
    @server.tool(:add) do |a, b|
      a + b
    end

    # List tools
    response = @server.process_message({
                                         method: 'tools/list',
                                         id: 2
                                       })

    assert_equal 1, response[:result][:tools].length
    assert_equal 'add', response[:result][:tools][0][:name]

    # Call tool
    response = @server.process_message({
                                         method: 'tools/call',
                                         id: 3,
                                         params: {
                                           name: 'add',
                                           arguments: { a: 5, b: 3 }
                                         }
                                       })

    assert_equal '8', response[:result][:content][0][:text]
  end

  def test_resource_registration_and_reading
    @server.resource('test://static') do
      'Static content'
    end

    @server.resource('test://{id}') do |id|
      "Dynamic content for #{id}"
    end

    # List resources
    response = @server.process_message({
                                         method: 'resources/list',
                                         id: 4
                                       })

    assert_equal 2, response[:result][:resources].length

    # Read static resource
    response = @server.process_message({
                                         method: 'resources/read',
                                         id: 5,
                                         params: { uri: 'test://static' }
                                       })

    assert_equal 'Static content', response[:result][:contents][0][:text]

    # Read dynamic resource
    response = @server.process_message({
                                         method: 'resources/read',
                                         id: 6,
                                         params: { uri: 'test://123' }
                                       })

    assert_equal 'Dynamic content for 123', response[:result][:contents][0][:text]
  end

  def test_prompt_registration_and_retrieval
    @server.prompt(:greeting) do |name|
      "Hello, #{name}!"
    end

    # List prompts
    response = @server.process_message({
                                         method: 'prompts/list',
                                         id: 7
                                       })

    assert_equal 1, response[:result][:prompts].length
    assert_equal 'greeting', response[:result][:prompts][0][:name]

    # Get prompt
    response = @server.process_message({
                                         method: 'prompts/get',
                                         id: 8,
                                         params: {
                                           name: 'greeting',
                                           arguments: { name: 'World' }
                                         }
                                       })

    assert_equal 'Hello, World!', response[:result][:messages][0][:content][:text]
  end

  def test_error_handling_for_unknown_method
    response = @server.process_message({
                                         method: 'unknown/method',
                                         id: 9
                                       })

    assert_equal MCP::Types::ErrorCode::METHOD_NOT_FOUND, response[:error][:code]
    assert_match(/Method not found/, response[:error][:message])
  end

  def test_error_handling_for_tool_execution_error
    @server.tool(:divide) do |a, b|
      raise 'Division by zero' if b == 0

      a / b
    end

    response = @server.process_message({
                                         method: 'tools/call',
                                         id: 10,
                                         params: {
                                           name: 'divide',
                                           arguments: { a: 10, b: 0 }
                                         }
                                       })

    assert_equal MCP::Types::ErrorCode::INTERNAL_ERROR, response[:error][:code]
    assert_match(/Division by zero/, response[:error][:message])
  end
end
