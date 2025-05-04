#!/usr/bin/env ruby
# weather_api_server_debug.rb - MCPサーバーのデバッグバージョン

require 'json'
require 'net/http'
require 'uri'

# 環境変数ファイルを読み込む
def load_env_file(filename = '.env')
  env_path = File.join(File.dirname(__FILE__), '..', filename)
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

# ツールの定義
TOOLS = {
  'get_forecast' => {
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
}

# メッセージを処理
def process_message(message)
  STDERR.puts "Received message: #{message.inspect}"
  
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
          name: 'weather-api',
          version: '1.0.0'
        }
      }
    }
  when 'tools/list'
    {
      jsonrpc: '2.0',
      id: message[:id],
      result: {
        tools: TOOLS.values
      }
    }
  when 'tools/call'
    handle_tool_call(message)
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

def handle_tool_call(message)
  tool_name = message[:params][:name]
  arguments = message[:params][:arguments] || {}
  
  case tool_name
  when 'get_forecast'
    city = arguments[:city]
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
STDERR.puts "Starting Weather API Debug Server..."

loop do
  begin
    # 標準入力から1行読み込む
    line = STDIN.gets
    break unless line
    
    STDERR.puts "Read line: #{line}"
    
    # JSON-RPCメッセージをパース
    begin
      message = JSON.parse(line, symbolize_names: true)
    rescue JSON::ParserError => e
      STDERR.puts "JSON parse error: #{e.message}"
      next
    end
    
    # メッセージを処理
    response = process_message(message)
    
    # レスポンスを送信
    if response
      STDERR.puts "Sending response: #{response.inspect}"
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
