# frozen_string_literal: true

require 'oauth2'
require 'json'
require 'dotenv'

module MCP
  class Client
    module Misoca
      class API
        attr_reader :access_token

        MISOCA_API_ENDPOINT = 'https://app.misoca.jp'
        MISOCA_API_VERSION = 'v3'
        
        def initialize(application_id = nil, app_secret_key = nil, redirect_uri = nil)
          Dotenv.load
          
          @application_id = application_id || ENV['MISOCA_APPLICATION_ID']
          @app_secret_key = app_secret_key || ENV['MISOCA_APP_SECRET_KEY']
          @redirect_uri = redirect_uri || ENV['MISOCA_REDIRECT_URI']
          
          raise ArgumentError, 'Missing Misoca API credentials. Please provide application_id and app_secret_key.' unless @application_id && @app_secret_key
        end
        
        # Generate the authorization URL
        def authorize_url(scope = 'read')
          oauth_client.auth_code.authorize_url(
            redirect_uri: @redirect_uri,
            scope: scope
          )
        end
        
        # Get access token using authorization code
        def get_access_token(code)
          token = oauth_client.auth_code.get_token(code, redirect_uri: @redirect_uri)
          @access_token = token
          token
        end
        
        # Refresh the access token
        def refresh_token!
          return false unless @access_token&.refresh_token
          
          @access_token = @access_token.refresh!
          true
        end
        
        # List all invoices
        def list_invoices(params = {})
          response = get("/#{MISOCA_API_VERSION}/invoices", params)
          response['invoices'] || []
        end
        
        # Get a specific invoice by ID
        def get_invoice(invoice_id)
          get("/#{MISOCA_API_VERSION}/invoices/#{invoice_id}")
        end
        
        # Download invoice PDF
        def download_invoice_pdf(invoice_id)
          get("/#{MISOCA_API_VERSION}/invoices/#{invoice_id}/pdf", {}, 'application/pdf')
        end
        
        private
        
        def oauth_client
          @oauth_client ||= OAuth2::Client.new(
            @application_id,
            @app_secret_key,
            site: MISOCA_API_ENDPOINT,
            authorize_url: '/oauth2/authorize',
            token_url: '/oauth2/token'
          )
        end
        
        def get(path, params = {}, accept = 'application/json')
          ensure_access_token
          
          response = @access_token.get(
            path,
            params: params,
            headers: { 'Accept' => accept }
          )
          
          return response.body if accept != 'application/json'
          
          JSON.parse(response.body)
        rescue OAuth2::Error => e
          handle_oauth_error(e)
        end
        
        def ensure_access_token
          raise 'No access token available. Please authorize first.' unless @access_token
          
          # Refresh token if expired
          refresh_token! if @access_token.expired?
        end
        
        def handle_oauth_error(error)
          if error.response.status == 401
            refresh_token!
            raise 'Failed to refresh access token. Please reauthorize.' unless @access_token
          else
            raise error
          end
        end
      end
    end
  end
end
