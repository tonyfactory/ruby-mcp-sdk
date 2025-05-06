# frozen_string_literal: true

require_relative 'misoca/client'
require_relative 'misoca/cli'
require_relative 'misoca/token_store'

module MCP
  class Client
    module Misoca
      # Convenience method to create a new Misoca client
      def self.new(application_id = nil, app_secret_key = nil, redirect_uri = nil)
        API.new(application_id, app_secret_key, redirect_uri)
      end
      
      # Load stored token from .env file
      def self.load_token
        TokenStore.new.load_token
      end
    end
  end
end
