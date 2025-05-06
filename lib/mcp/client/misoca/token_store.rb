# frozen_string_literal: true

require 'dotenv'
require 'oauth2'
require 'time'

module MCP
  class Client
    module Misoca
      class TokenStore
        def initialize
          Dotenv.load
        end

        def load_token
          return nil unless ENV['MISOCA_ACCESS_TOKEN'] && ENV['MISOCA_REFRESH_TOKEN'] && ENV['MISOCA_TOKEN_EXPIRES_AT']

          OAuth2::AccessToken.new(
            create_client,
            ENV['MISOCA_ACCESS_TOKEN'],
            {
              refresh_token: ENV['MISOCA_REFRESH_TOKEN'],
              expires_at: ENV['MISOCA_TOKEN_EXPIRES_AT'].to_i
            }
          )
        end

        def save_token(token)
          update_env_file(
            'MISOCA_ACCESS_TOKEN' => token.token,
            'MISOCA_REFRESH_TOKEN' => token.refresh_token,
            'MISOCA_TOKEN_EXPIRES_AT' => token.expires_at.to_s
          )
        end

        private

        def create_client
          OAuth2::Client.new(
            ENV['MISOCA_APPLICATION_ID'],
            ENV['MISOCA_APP_SECRET_KEY'],
            site: 'https://app.misoca.jp',
            authorize_url: '/oauth2/authorize',
            token_url: '/oauth2/token'
          )
        end

        def update_env_file(values)
          env_file = File.join(Dir.pwd, '.env')
          env_content = File.exist?(env_file) ? File.read(env_file) : ""

          values.each do |key, value|
            if env_content.match?(/^#{key}=.*$/)
              env_content.gsub!(/^#{key}=.*$/, "#{key}=#{value}")
            else
              env_content += "\n#{key}=#{value}"
            end
          end

          File.write(env_file, env_content)
        end
      end
    end
  end
end
