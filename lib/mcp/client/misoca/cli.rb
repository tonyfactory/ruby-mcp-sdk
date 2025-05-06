# frozen_string_literal: true

require_relative 'client'
require 'fileutils'

module MCP
  class Client
    module Misoca
      class CLI
        def initialize
          @client = API.new
        end

        def run(args)
          command = args.shift&.downcase
          case command
          when 'authorize'
            authorize
          when 'callback'
            handle_callback(args.first)
          when 'list'
            list_invoices
          when 'get'
            get_invoice(args.first)
          when 'download'
            download_invoice(args.first, args[1])
          else
            show_help
          end
        end

        private

        def authorize
          auth_url = @client.authorize_url('read')
          puts "Please open the following URL in your browser to authorize the application:"
          puts auth_url
          puts "\nAfter authorization, you will be redirected to your callback URL with a code parameter."
          puts "Run the callback command with the code: misoca callback CODE"
        end

        def handle_callback(code)
          return puts "Error: Authorization code required" unless code

          begin
            token = @client.get_access_token(code)
            puts "Successfully authenticated!"
            puts "Access token: #{token.token}"
            puts "Refresh token: #{token.refresh_token}"
            puts "Token expires at: #{token.expires_at}"

            # Save token to .env file
            env_file = File.join(Dir.pwd, '.env')
            env_content = File.exist?(env_file) ? File.read(env_file) : ""

            # Update or add token variables
            env_content.gsub!(/^MISOCA_ACCESS_TOKEN=.*$/, "MISOCA_ACCESS_TOKEN=#{token.token}")
            env_content.gsub!(/^MISOCA_REFRESH_TOKEN=.*$/, "MISOCA_REFRESH_TOKEN=#{token.refresh_token}")
            env_content.gsub!(/^MISOCA_TOKEN_EXPIRES_AT=.*$/, "MISOCA_TOKEN_EXPIRES_AT=#{token.expires_at}")

            unless env_content.include?('MISOCA_ACCESS_TOKEN=')
              env_content += "\nMISOCA_ACCESS_TOKEN=#{token.token}"
            end
            unless env_content.include?('MISOCA_REFRESH_TOKEN=')
              env_content += "\nMISOCA_REFRESH_TOKEN=#{token.refresh_token}"
            end
            unless env_content.include?('MISOCA_TOKEN_EXPIRES_AT=')
              env_content += "\nMISOCA_TOKEN_EXPIRES_AT=#{token.expires_at}"
            end

            File.write(env_file, env_content)
            puts "Tokens saved to #{env_file}"
          rescue => e
            puts "Error: #{e.message}"
          end
        end

        def list_invoices
          begin
            invoices = @client.list_invoices
            if invoices.empty?
              puts "No invoices found."
            else
              puts "Found #{invoices.size} invoices:"
              invoices.each do |invoice|
                puts "ID: #{invoice['id']}, Title: #{invoice['title']}, Issue Date: #{invoice['issue_date']}, Amount: #{invoice['total_amount']}"
              end
            end
          rescue => e
            puts "Error: #{e.message}"
          end
        end

        def get_invoice(invoice_id)
          return puts "Error: Invoice ID required" unless invoice_id

          begin
            invoice = @client.get_invoice(invoice_id)
            puts "Invoice details:"
            puts JSON.pretty_generate(invoice)
          rescue => e
            puts "Error: #{e.message}"
          end
        end

        def download_invoice(invoice_id, output_path = nil)
          return puts "Error: Invoice ID required" unless invoice_id

          begin
            pdf_data = @client.download_invoice_pdf(invoice_id)
            
            # Default output path if not provided
            output_path ||= File.join(Dir.pwd, "invoice_#{invoice_id}.pdf")
            
            # Ensure directory exists
            FileUtils.mkdir_p(File.dirname(output_path))
            
            # Write PDF to file
            File.binwrite(output_path, pdf_data)
            puts "Invoice PDF downloaded to: #{output_path}"
          rescue => e
            puts "Error: #{e.message}"
          end
        end

        def show_help
          puts "Misoca API Client"
          puts "\nUsage:"
          puts "  misoca authorize                       - Get authorization URL"
          puts "  misoca callback CODE                   - Handle OAuth callback with authorization code"
          puts "  misoca list                            - List all invoices"
          puts "  misoca get INVOICE_ID                  - Get details of a specific invoice"
          puts "  misoca download INVOICE_ID [FILEPATH]  - Download invoice as PDF"
        end
      end
    end
  end
end
