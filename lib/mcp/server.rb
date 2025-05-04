# frozen_string_literal: true

require_relative 'types'

module MCP
  class Server
    attr_reader :name, :version, :capabilities

    def initialize(name:, version: '1.0.0')
      @name = name
      @version = version
      @capabilities = Types::ServerCapabilities.new
      @handlers = {}
      @tools = {}
      @resources = {}
      @prompts = {}

      setup_default_handlers
    end

    def handle(method, &block)
      @handlers[method] = block
    end

    def tool(name, &block)
      @tools[name] = block
      update_capabilities
    end

    def resource(uri_pattern, &block)
      @resources[uri_pattern] = block
      update_capabilities
    end

    def prompt(name, &block)
      @prompts[name] = block
      update_capabilities
    end

    def process_message(message)
      case message
      in { method: String, id: Integer, params: params }
        handle_request(message[:method], message[:id], params)
      in { method: String, id: Integer }
        handle_request(message[:method], message[:id], nil)
      in { method: String, params: params }
        handle_notification(message[:method], params)
      in { method: String }
        handle_notification(message[:method], nil)
      else
        error_response(nil, Types::ErrorCode::INVALID_REQUEST, 'Invalid message format')
      end
    end

    private

    def setup_default_handlers
      # Initialize handler
      handle('initialize') do |_params|
        {
          protocolVersion: '2024-11-05',
          capabilities: @capabilities.to_h,
          serverInfo: {
            name: @name,
            version: @version
          }
        }
      end

      # List tools handler
      handle('tools/list') do |_params|
        {
          tools: @tools.keys.map do |name|
            {
              name: name.to_s,
              description: "Tool: #{name}",
              inputSchema: {
                type: 'object',
                properties: {},
                required: []
              }
            }
          end
        }
      end

      # Call tool handler
      handle('tools/call') do |params|
        name = params[:name]&.to_sym
        arguments = params[:arguments] || {}

        raise "Tool not found: #{name}" unless @tools.key?(name)

        result = if arguments.is_a?(Hash) && !arguments.empty?
                   args = arguments.values
                   @tools[name].call(*args)
                 else
                   @tools[name].call
                 end
        { content: [{ type: 'text', text: result.to_s }] }
      end

      # List resources handler
      handle('resources/list') do |_params|
        {
          resources: @resources.keys.map do |pattern|
            {
              uri: pattern.to_s,
              name: pattern.to_s,
              description: "Resource: #{pattern}"
            }
          end
        }
      end

      # Read resource handler
      handle('resources/read') do |params|
        uri = params[:uri]

        # Find matching resource pattern
        @resources.each do |pattern, handler|
          next unless match_data = match_uri_pattern(pattern.to_s, uri)

          result = if match_data.is_a?(Hash) && !match_data.empty?
                     args = match_data.values
                     handler.call(*args)
                   else
                     handler.call
                   end
          return {
            contents: [{
              uri: uri,
              mimeType: 'application/json',
              text: result.to_s
            }]
          }
        end

        raise "Resource not found: #{uri}"
      end

      # List prompts handler
      handle('prompts/list') do |_params|
        {
          prompts: @prompts.keys.map do |name|
            {
              name: name.to_s,
              description: "Prompt: #{name}"
            }
          end
        }
      end

      # Get prompt handler
      handle('prompts/get') do |params|
        name = params[:name]&.to_sym
        arguments = params[:arguments] || {}

        raise "Prompt not found: #{name}" unless @prompts.key?(name)

        result = if arguments.is_a?(Hash) && !arguments.empty?
                   args = arguments.values
                   @prompts[name].call(*args)
                 else
                   @prompts[name].call
                 end
        {
          messages: [{
            role: 'user',
            content: {
              type: 'text',
              text: result.to_s
            }
          }]
        }
      end
    end

    def handle_request(method, id, params)
      handler = @handlers[method]

      if handler
        begin
          result = handler.call(params)
          Types::Response.new(id: id, result: result).to_h
        rescue StandardError => e
          error_response(id, Types::ErrorCode::INTERNAL_ERROR, e.message)
        end
      else
        error_response(id, Types::ErrorCode::METHOD_NOT_FOUND, "Method not found: #{method}")
      end
    end

    def handle_notification(method, params)
      # Notifications don't send responses
      handler = @handlers[method]
      handler&.call(params)
    rescue StandardError => e
      # Log error but don't send response for notifications
      warn "Error handling notification: #{e.message}"
    end

    def error_response(id, code, message)
      Types::Response.new(
        id: id,
        error: Types::ErrorResponse.new(code: code, message: message).to_h
      ).to_h
    end

    def update_capabilities
      @capabilities = Types::ServerCapabilities.new(
        tools: @tools.empty? ? nil : {},
        resources: @resources.empty? ? nil : {},
        prompts: @prompts.empty? ? nil : {}
      )
    end

    def match_uri_pattern(pattern, uri)
      # Simple pattern matching for URIs like "users://{user_id}/profile"
      regex_pattern = pattern.gsub(/\{([^}]+)\}/, '(?<\1>[^/]+)')
      regex = Regexp.new("^#{regex_pattern}$")

      return unless match = regex.match(uri)

      match.named_captures.transform_keys(&:to_sym)
    end
  end
end
