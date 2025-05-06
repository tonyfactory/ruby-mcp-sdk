#!/usr/bin/env ruby
# weather_api_server_env.rb
#
# This is an MCP weather server using real weather API (OpenWeatherMap).
# It loads API key from .env file for security.
#
# Usage:
#   1. Copy .env.example to .env and set your API key
#   2. ruby weather_api_server_env.rb

require_relative '../../lib/mcp/server/fastmcp'
require 'json'
require 'net/http'
require 'uri'

# 環境変数ファイルを読み込む簡易的な実装
def load_env_file(filename = '.env')
  # アプリケーションルートの.envファイルを探す
  script_dir = File.dirname(__FILE__)
  root_dir = File.expand_path(File.join(script_dir, '..', '..'))
  env_path = File.join(root_dir, filename)
  
  unless File.exist?(env_path)
    # 後方互換性のためスクリプトディレクトリも確認
    env_path = File.join(script_dir, filename)
    return unless File.exist?(env_path)
  end
  
  File.readlines(env_path).each do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    
    key, value = line.split('=', 2)
    ENV[key.strip] = value.strip if key && value
  end
end

# .envファイルから環境変数を読み込み
load_env_file

# MCPサーバーを作成
mcp = MCP::FastMCP.new('weather-api')

# APIキーの確認
API_KEY = ENV['OPENWEATHER_API_KEY']
if API_KEY.nil? || API_KEY.empty?
  STDERR.puts "Error: OPENWEATHER_API_KEY not found in .env file"
  STDERR.puts "Please create a .env file based on .env.example and set your API key"
  exit 1
end

# 都市名から天気予報を取得するツール
mcp.tool(:get_forecast) do |city|
  begin
    # OpenWeatherMap API エンドポイント
    uri = URI("https://api.openweathermap.org/data/2.5/weather")
    params = {
      q: city,
      appid: API_KEY,
      units: 'metric',  # 摂氏で取得
      lang: 'ja'        # 日本語で取得（オプション）
    }
    uri.query = URI.encode_www_form(params)
    
    # APIリクエスト
    response = Net::HTTP.get_response(uri)
    
    if response.code != '200'
      error_data = JSON.parse(response.body)
      return { error: "API Error: #{error_data['message']}" }.to_json
    end
    
    data = JSON.parse(response.body)
    
    # レスポンスを整形
    {
      city: data['name'],
      country: data['sys']['country'],
      temperature: data['main']['temp'],
      feels_like: data['main']['feels_like'],
      conditions: data['weather'][0]['description'],
      humidity: data['main']['humidity'],
      wind_speed: data['wind']['speed'],
      pressure: data['main']['pressure'],
      forecast: "#{data['name']}の天気は#{data['weather'][0]['description']}で、気温は#{data['main']['temp']}°Cです。"
    }.to_json
  rescue => e
    { error: "Failed to fetch weather data: #{e.message}" }.to_json
  end
end

# 5日間の天気予報を取得するツール
mcp.tool(:get_5day_forecast) do |city|
  begin
    # OpenWeatherMap 5 day forecast API
    uri = URI("https://api.openweathermap.org/data/2.5/forecast")
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
    
    # 1日ごとの予報を抽出（正午のデータを使用）
    daily_forecasts = data['list'].select do |item|
      Time.at(item['dt']).hour == 12
    end.map do |item|
      {
        date: Time.at(item['dt']).strftime('%Y-%m-%d'),
        temperature: item['main']['temp'],
        conditions: item['weather'][0]['description'],
        humidity: item['main']['humidity'],
        wind_speed: item['wind']['speed']
      }
    end
    
    {
      city: data['city']['name'],
      country: data['city']['country'],
      forecasts: daily_forecasts
    }.to_json
  rescue => e
    { error: "Failed to fetch 5-day forecast: #{e.message}" }.to_json
  end
end

# 緯度経度から天気を取得するツール
mcp.tool(:get_weather_by_coordinates) do |lat, lon|
  begin
    uri = URI("https://api.openweathermap.org/data/2.5/weather")
    params = {
      lat: lat,
      lon: lon,
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
      location: "#{data['name']}, #{data['sys']['country']}",
      coordinates: { lat: data['coord']['lat'], lon: data['coord']['lon'] },
      temperature: data['main']['temp'],
      conditions: data['weather'][0]['description'],
      humidity: data['main']['humidity'],
      wind_speed: data['wind']['speed']
    }.to_json
  rescue => e
    { error: "Failed to fetch weather by coordinates: #{e.message}" }.to_json
  end
end

# サーバーを実行
if __FILE__ == $0
  STDERR.puts "Starting Weather API Server with environment file..."
  STDERR.puts "Using OpenWeatherMap API"
  STDERR.puts "API Key loaded from .env file"
  STDERR.puts "\nAvailable tools:"
  STDERR.puts "  - get_forecast: Get current weather for a city"
  STDERR.puts "  - get_5day_forecast: Get 5-day forecast for a city"
  STDERR.puts "  - get_weather_by_coordinates: Get weather by latitude and longitude"
  mcp.run
end
