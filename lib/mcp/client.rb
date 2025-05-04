# frozen_string_literal: true

require "json"
require "async"
require "async/queue"
require_relative "types"

module MCP
  class Client
    class Error < StandardError; end
    class TimeoutError < Error; end
    class ProtocolError < Error; end

    def initialize(transport)
      @transport = transport
      @request_id = 0
      @pending_requests = {}
      @mutex = Mutex.new
      @initialized = false
    end

    def initialize!
      raise "Already initialized" if @initialized

      response = request("initialize", {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: {
          name: "MCP Ruby Client",
          version: "0.1.0"
        }
      })

      @server_capabilities = response[:capabilities]
      @server_info = response[:serverInfo]
      @initialized = true

      response
    end

    def list_tools
      ensure_initialized!
      response = request("tools/list")
      response[:tools].map do |tool|
        Types::Tool.new(
          name: tool[:name],
          description: tool[:description],
          input_schema: tool[:inputSchema]
        )
      end
    end

    def call_tool(name, arguments: {})
      ensure_initialized!
      response = request("tools/call", {
        name: name,
        arguments: arguments
      })
      
      content = response[:content]
      if content.is_a?(Array) && content.first[:type] == "text"
        content.first[:text]
      else
        content
      end
    end

    def list_resources
      ensure_initialized!
      response = request("resources/list")
      response[:resources].map do |resource|
        Types::Resource.new(
          uri: resource[:uri],
          name: resource[:name],
          description: resource[:description],
          mime_type: resource[:mimeType]
        )
      end
    end

    def read_resource(uri)
      ensure_initialized!
      response = request("resources/read", { uri: uri })
      contents = response[:contents]
      
      if contents.is_a?(Array) && !contents.empty?
        content = contents.first
        [content[:text], content[:mimeType]]
      else
        [nil, nil]
      end
    end

    def list_prompts
      ensure_initialized!
      response = request("prompts/list")
      response[:prompts].map do |prompt|
        Types::Prompt.new(
          name: prompt[:name],
          description: prompt[:description],
          arguments: prompt[:arguments]&.map do |arg|
            Types::PromptArgument.new(
              name: arg[:name],
              description: arg[:description],
              required: arg[:required]
            )
          end || []
        )
      end
    end

    def get_prompt(name, arguments: {})
      ensure_initialized!
      response = request("prompts/get", {
        name: name,
        arguments: arguments
      })
      
      messages = response[:messages]
      if messages.is_a?(Array) && !messages.empty?
        message = messages.first
        message[:content][:text] if message[:content][:type] == "text"
      end
    end

    def close
      # Clean up resources
      @pending_requests.clear
      @initialized = false
    end

    private

    def ensure_initialized!
      raise "Client not initialized. Call initialize! first." unless @initialized
    end

    def request(method, params = nil, timeout: 30)
      id = next_request_id
      message = Types::Request.new(id: id, method: method, params: params).to_h
      
      response_future = Async::Queue.new
      @pending_requests[id] = response_future

      @transport.send_message(message)

      begin
        Async do |task|
          task.with_timeout(timeout) do
            response = response_future.dequeue
            
            if response[:error]
              raise ProtocolError, "Error: #{response[:error][:message]}"
            else
              response[:result]
            end
          end
        end.wait
      rescue Async::TimeoutError
        raise TimeoutError, "Request timed out after #{timeout} seconds"
      ensure
        @pending_requests.delete(id)
      end
    end

    def next_request_id
      @mutex.synchronize do
        @request_id += 1
      end
    end

    def handle_response(message)
      id = message[:id]
      return unless id

      response_future = @pending_requests[id]
      response_future&.enqueue(message)
    end
  end
end
