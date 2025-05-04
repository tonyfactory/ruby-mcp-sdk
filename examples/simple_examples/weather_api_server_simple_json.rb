#!/usr/bin/env ruby
# weather_api_server_simple_json.rb
#
# Simple JSON-RPC MCP server for OpenWeatherMap API

require 'json'
require 'net/http'
require 'uri'

# 環境変数ファイルを読み込む
def load_env_file(filename = '.env')
  env_path = File.join(File.dirname(__FILE__), filename)
  return unless File.exist?(env_path)
  
  File.readlines(env_path).each do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    
    key, value = line.split('=', 2)
    ENV[key.strip] = value.strip if key && value
  end
end

load_env_file

# APIキーの確認
API_KEY = ENV['OPENWEATHER_API_KEY']
if API_KEY.nil? || API_KEY.empty?
  STDERR.puts "Error: OPENWEATHER_API_KEY not found in .env file"
  exit 1
end

def get_forecast(city)
  uri = URI("https://api.openweathermap.org/data/2.5/weather")
  params = {
    q: city,
    appid: API_KEY,
    units: 'metric',
    lang: 'ja'
  }
  uri.query = URI.encode_www_form(params)
  
  response = Net::HTTP.get_response(uri)
  
  if response.code != '200'
    error_data = JSON.parse(response.body)
    return { error: "API Error: #{error_data['message']}" }.to_json
  end
  
  data = JSON.parse(response.body)
  
  {
    city: data['name'],
    country: data['sys']['country'],
    temperature: data['main']['temp'],
    feels_like: data['main']['feels_like'],
    conditions: data['weather'][0]['description'],
    humidity: data['main']['humidity'],
    wind_speed: data['wind']['speed']
  }.to_json
rescue => e
  { error: "Failed to fetch weather data: #{e.message}" }.to_json
end

# メインループ
STDERR.puts "Starting Weather API Server (Simple JSON mode)..."

loop do
  begin
    # Read line from STDIN
    line = STDIN.gets
    break unless line
    
    line = line.strip
    next if line.empty?
    
    # Parse JSON-RPC message
    begin
      message = JSON.parse(line, symbolize_names: true)
      STDERR.puts "Received: #{message[:method]}"
    rescue JSON::ParserError => e
      STDERR.puts "JSON parse error: #{e.message}"
      next
    end
    
    # Process message
    response = if message[:method] == 'notifications/initialized'
      # Notification messages don't need a response
      nil
    elsif message[:id].nil?
      # If no id is provided, this might be a notification, don't respond
      STDERR.puts "No id provided for method: #{message[:method]}"
      nil
    else
      case message[:method]
      when 'initialize'
        {
          jsonrpc: '2.0',
          id: message[:id],
          result: {
            protocolVersion: '2024-11-05',
            capabilities: {
              tools: {}
            },
            serverInfo: {
              name: 'weather-api-simple',
              version: '1.0.0'
            }
          }
        }
      when 'tools/list'
        {
          jsonrpc: '2.0',
          id: message[:id],
          result: {
            tools: [
              {
                name: 'get_forecast',
                description: 'Get current weather for a city',
                inputSchema: {
                  type: 'object',
                  properties: {
                    city: { type: 'string', description: 'City name' }
                  },
                  required: ['city']
                }
              }
            ]
          }
        }
      when 'resources/list'
        {
          jsonrpc: '2.0',
          id: message[:id],
          result: {
            resources: []
          }
        }
      when 'prompts/list'
        {
          jsonrpc: '2.0',
          id: message[:id],
          result: {
            prompts: []
          }
        }
      when 'tools/call'
        tool_name = message[:params][:name]
        arguments = message[:params][:arguments] || {}
        
        if tool_name == 'get_forecast'
          city = arguments[:city] || arguments['city']
          result = get_forecast(city)
          {
            jsonrpc: '2.0',
            id: message[:id],
            result: {
              content: [{ type: 'text', text: result }]
            }
          }
        else
          {
            jsonrpc: '2.0',
            id: message[:id],
            error: {
              code: -32601,
              message: "Tool not found: #{tool_name}"
            }
          }
        end
      else
        {
          jsonrpc: '2.0',
          id: message[:id],
          error: {
            code: -32601,
            message: "Method not found: #{message[:method]}"
          }
        }
      end
    end
    
    # Send response
    if response
      STDERR.puts "Sending response for: #{message[:method]}"
      STDOUT.puts(response.to_json)
      STDOUT.flush
    end
  rescue EOFError
    break
  rescue => e
    STDERR.puts "Error: #{e.message}"
    STDERR.puts e.backtrace.join("\n")
  end
end

STDERR.puts "Server shutdown"
