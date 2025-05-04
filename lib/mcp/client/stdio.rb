# frozen_string_literal: true

require_relative '../client'
require_relative '../transport/stdio'
require 'open3'

module MCP
  class Client
    class Stdio
      def self.connect(command)
        command = [command] if command.is_a?(String)

        Open3.popen3(*command) do |stdin, stdout, _stderr, wait_thread|
          transport = Transport::Stdio.new(
            input: stdout,
            output: stdin,
            error: $stderr
          )

          client = Client.new(transport)

          # Start message processing in background thread
          thread = Thread.new do
            transport.start do |message|
              client.send(:handle_response, message)
            end
          end

          begin
            if block_given?
              yield client
            else
              client
            end
          ensure
            client.close
            thread.kill if thread.alive?
            begin
              Process.kill('TERM', wait_thread.pid)
            rescue StandardError
              nil
            end
          end
        end
      end
    end
  end
end
