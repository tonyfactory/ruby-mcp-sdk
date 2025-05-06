#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'mcp'
require 'dotenv'

# Load environment variables from .env file
Dotenv.load

# Example usage of the Misoca API client
class MisocaExample
  def initialize
    # Create a new Misoca client
    @client = MCP::Client::Misoca.new
  end

  def run
    # Check if we have an access token
    token = MCP::Client::Misoca.load_token
    
    if token
      @client.access_token = token
      list_invoices
    else
      authorize
    end
  end

  def authorize
    # Generate authorization URL
    auth_url = @client.authorize_url('read')
    
    puts "Please open the following URL in your browser to authorize the application:"
    puts auth_url
    puts "\nAfter authorization, you will be redirected back with a code."
    print "Enter the code: "
    
    code = gets.chomp
    
    # Get access token using the authorization code
    @client.get_access_token(code)
    
    puts "Successfully authenticated!"
    list_invoices
  end

  def list_invoices
    puts "Fetching invoices..."
    
    invoices = @client.list_invoices
    
    if invoices.empty?
      puts "No invoices found."
    else
      puts "Found #{invoices.size} invoices:"
      
      invoices.each do |invoice|
        puts "ID: #{invoice['id']}, Title: #{invoice['title']}, Issue Date: #{invoice['issue_date']}, Amount: #{invoice['total_amount']}"
      end
      
      # Download the first invoice as PDF
      if invoices.first
        invoice_id = invoices.first['id']
        download_invoice(invoice_id)
      end
    end
  end

  def download_invoice(invoice_id)
    puts "Downloading invoice #{invoice_id} as PDF..."
    
    pdf_data = @client.download_invoice_pdf(invoice_id)
    output_path = "invoice_#{invoice_id}.pdf"
    
    File.binwrite(output_path, pdf_data)
    puts "Invoice PDF downloaded to: #{output_path}"
  end
end

# Run the example if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  MisocaExample.new.run
end
