# frozen_string_literal: true

require 'json'

module MCP
  module Transport
    class Stdio
      def initialize(input: $stdin, output: $stdout, error: $stderr)
        @input = input
        @output = output
        @error = error
        @mutex = Mutex.new
      end

      def start
        # Read messages in a loop
        loop do
          # Read message length header
          header = @input.gets
          break unless header

          if header =~ /Content-Length: (\d+)/i
            content_length = ::Regexp.last_match(1).to_i

            # Read the blank line after headers
            @input.gets

            # Read the JSON content
            content = @input.read(content_length)
            message = JSON.parse(content, symbolize_names: true)

            # Process the message
            yield message if block_given?
          end
        rescue EOFError
          break
        rescue StandardError => e
          log_error("Error reading message: #{e.message}")
        end
      end

      def send_message(message)
        @mutex.synchronize do
          json = JSON.generate(message)
          @output.write("Content-Length: #{json.bytesize}\r\n\r\n")
          @output.write(json)
          @output.flush
        end
      end

      private

      def log_error(message)
        @error.puts("MCP Error: #{message}")
      end
    end
  end
end
