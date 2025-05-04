# frozen_string_literal: true

module MCP
  module Types
    # Base message structure
    class Message
      attr_reader :jsonrpc, :id

      def initialize(id:)
        @jsonrpc = '2.0'
        @id = id
      end

      def to_h
        {
          jsonrpc: @jsonrpc,
          id: @id
        }
      end
    end

    # Request message
    class Request < Message
      attr_reader :method, :params

      def initialize(id:, method:, params: nil)
        super(id: id)
        @method = method
        @params = params
      end

      def to_h
        result = super
        result[:method] = @method
        result[:params] = @params if @params
        result
      end
    end

    # Response message
    class Response < Message
      attr_reader :result, :error

      def initialize(id:, result: nil, error: nil)
        super(id: id)
        @result = result
        @error = error
      end

      def to_h
        result = super
        if @error
          result[:error] = @error
        else
          result[:result] = @result
        end
        result
      end
    end

    # Notification message
    class Notification
      attr_reader :jsonrpc, :method, :params

      def initialize(method:, params: nil)
        @jsonrpc = '2.0'
        @method = method
        @params = params
      end

      def to_h
        result = {
          jsonrpc: @jsonrpc,
          method: @method
        }
        result[:params] = @params if @params
        result
      end
    end

    # Tool definition
    class Tool
      attr_reader :name, :description, :input_schema

      def initialize(name:, description:, input_schema:)
        @name = name
        @description = description
        @input_schema = input_schema
      end

      def to_h
        {
          name: @name,
          description: @description,
          inputSchema: @input_schema
        }
      end
    end

    # Resource definition
    class Resource
      attr_reader :uri, :name, :description, :mime_type

      def initialize(uri:, name:, description: nil, mime_type: nil)
        @uri = uri
        @name = name
        @description = description
        @mime_type = mime_type
      end

      def to_h
        result = {
          uri: @uri,
          name: @name
        }
        result[:description] = @description if @description
        result[:mimeType] = @mime_type if @mime_type
        result
      end
    end

    # Prompt definition
    class Prompt
      attr_reader :name, :description, :arguments

      def initialize(name:, description:, arguments: [])
        @name = name
        @description = description
        @arguments = arguments
      end

      def to_h
        {
          name: @name,
          description: @description,
          arguments: @arguments.map(&:to_h)
        }
      end
    end

    # Prompt argument
    class PromptArgument
      attr_reader :name, :description, :required

      def initialize(name:, description: nil, required: false)
        @name = name
        @description = description
        @required = required
      end

      def to_h
        result = {
          name: @name,
          required: @required
        }
        result[:description] = @description if @description
        result
      end
    end

    # Server capabilities
    class ServerCapabilities
      attr_reader :prompts, :resources, :tools, :logging

      def initialize(prompts: nil, resources: nil, tools: nil, logging: nil)
        @prompts = prompts
        @resources = resources
        @tools = tools
        @logging = logging
      end

      def to_h
        result = {}
        result[:prompts] = @prompts if @prompts
        result[:resources] = @resources if @resources
        result[:tools] = @tools if @tools
        result[:logging] = @logging if @logging
        result
      end
    end

    # Server information
    class Implementation
      attr_reader :name, :version

      def initialize(name:, version:)
        @name = name
        @version = version
      end

      def to_h
        {
          name: @name,
          version: @version
        }
      end
    end

    # Error codes
    module ErrorCode
      PARSE_ERROR = -32_700
      INVALID_REQUEST = -32_600
      METHOD_NOT_FOUND = -32_601
      INVALID_PARAMS = -32_602
      INTERNAL_ERROR = -32_603
    end

    # Error response
    class ErrorResponse
      attr_reader :code, :message, :data

      def initialize(code:, message:, data: nil)
        @code = code
        @message = message
        @data = data
      end

      def to_h
        result = {
          code: @code,
          message: @message
        }
        result[:data] = @data if @data
        result
      end
    end
  end
end
