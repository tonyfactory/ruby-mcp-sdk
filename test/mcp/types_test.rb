# frozen_string_literal: true

require "test_helper"

class MCP::TypesTest < Minitest::Test
  def test_request_creation
    request = MCP::Types::Request.new(id: 1, method: "test", params: { foo: "bar" })
    
    assert_equal 1, request.id
    assert_equal "test", request.method
    assert_equal({ foo: "bar" }, request.params)
    
    hash = request.to_h
    assert_equal "2.0", hash[:jsonrpc]
    assert_equal 1, hash[:id]
    assert_equal "test", hash[:method]
    assert_equal({ foo: "bar" }, hash[:params])
  end
  
  def test_response_creation_with_result
    response = MCP::Types::Response.new(id: 1, result: { status: "ok" })
    
    hash = response.to_h
    assert_equal "2.0", hash[:jsonrpc]
    assert_equal 1, hash[:id]
    assert_equal({ status: "ok" }, hash[:result])
    assert_nil hash[:error]
  end
  
  def test_response_creation_with_error
    error = MCP::Types::ErrorResponse.new(code: -32600, message: "Invalid Request")
    response = MCP::Types::Response.new(id: 1, error: error.to_h)
    
    hash = response.to_h
    assert_equal "2.0", hash[:jsonrpc]
    assert_equal 1, hash[:id]
    assert_nil hash[:result]
    assert_equal(-32600, hash[:error][:code])
    assert_equal("Invalid Request", hash[:error][:message])
  end
  
  def test_notification_creation
    notification = MCP::Types::Notification.new(method: "notify", params: { event: "test" })
    
    hash = notification.to_h
    assert_equal "2.0", hash[:jsonrpc]
    assert_equal "notify", hash[:method]
    assert_equal({ event: "test" }, hash[:params])
  end
  
  def test_tool_creation
    tool = MCP::Types::Tool.new(
      name: "add",
      description: "Add two numbers",
      input_schema: {
        type: "object",
        properties: {
          a: { type: "number" },
          b: { type: "number" }
        },
        required: ["a", "b"]
      }
    )
    
    hash = tool.to_h
    assert_equal "add", hash[:name]
    assert_equal "Add two numbers", hash[:description]
    assert_equal "object", hash[:inputSchema][:type]
  end
  
  def test_resource_creation
    resource = MCP::Types::Resource.new(
      uri: "file://test.txt",
      name: "Test File",
      description: "A test file",
      mime_type: "text/plain"
    )
    
    hash = resource.to_h
    assert_equal "file://test.txt", hash[:uri]
    assert_equal "Test File", hash[:name]
    assert_equal "A test file", hash[:description]
    assert_equal "text/plain", hash[:mimeType]
  end
  
  def test_prompt_creation
    argument = MCP::Types::PromptArgument.new(
      name: "code",
      description: "Code to review",
      required: true
    )
    
    prompt = MCP::Types::Prompt.new(
      name: "review_code",
      description: "Review code",
      arguments: [argument]
    )
    
    hash = prompt.to_h
    assert_equal "review_code", hash[:name]
    assert_equal "Review code", hash[:description]
    assert_equal 1, hash[:arguments].length
    assert_equal "code", hash[:arguments][0][:name]
    assert_equal true, hash[:arguments][0][:required]
  end
end
