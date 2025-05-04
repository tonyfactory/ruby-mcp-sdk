# frozen_string_literal: true

require "json"
require "async"
require "async/io/stream"

module MCP
  module Transport
    class Stdio
      def initialize(input: $stdin, output: $stdout, error: $stderr)
        @input = input
        @output = output
        @error = error
        @mutex = Mutex.new
      end

      def start(&block)
        Async do |task|
          input_stream = Async::IO::Stream.new(
            Async::IO::Generic.new(@input)
          )
          
          output_stream = Async::IO::Stream.new(
            Async::IO::Generic.new(@output)
          )

          # Read messages in a loop
          task.async do
            loop do
              begin
                # Read message length header
                header = input_stream.gets("\n")
                break unless header

                if header =~ /Content-Length: (\d+)/i
                  content_length = $1.to_i
                  
                  # Read the blank line after headers
                  input_stream.gets("\n")
                  
                  # Read the JSON content
                  content = input_stream.read(content_length)
                  message = JSON.parse(content, symbolize_names: true)
                  
                  # Process the message
                  yield message if block_given?
                end
              rescue EOFError
                break
              rescue => e
                log_error("Error reading message: #{e.message}")
              end
            end
          end

          # Keep the async block running
          task.wait
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
