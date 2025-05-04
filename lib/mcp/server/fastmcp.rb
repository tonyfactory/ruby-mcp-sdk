# frozen_string_literal: true

require_relative "../server"
require_relative "../transport/stdio"

module MCP
  module Server
    class FastMCP < MCP::Server
      def initialize(name, version: "1.0.0")
        super(name: name, version: version)
      end

      def tool(name, description: nil, &block)
        super(name, &block)
      end

      def resource(uri_pattern, description: nil, &block)
        super(uri_pattern, &block)
      end

      def prompt(name, description: nil, &block)
        super(name, &block)
      end

      def run
        transport = Transport::Stdio.new
        
        transport.start do |message|
          response = process_message(message)
          transport.send_message(response) if response
        end
      end
    end
  end
end
