#!/usr/bin/env ruby
# weather_api_server_with_key.rb
#
# This is an MCP weather server using real weather API (OpenWeatherMap).
# API key is embedded for convenience (not recommended for production).
#
# Usage:
#   ruby weather_api_server_with_key.rb

require_relative '../../lib/mcp/server/fastmcp'
require 'json'
require 'net/http'
require 'uri'

# MCPサーバーを作成
mcp = MCP::FastMCP.new('weather-api')

# APIキーを直接設定（開発/デモ用）
API_KEY = "c6ad2a3815d8de32594e721fc0750c01"

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
  puts "Starting Weather API Server with embedded API key..."
  puts "Using OpenWeatherMap API"
  puts "API Key: #{API_KEY[0..10]}..." # 一部のみ表示
  puts "\nAvailable tools:"
  puts "  - get_forecast: Get current weather for a city"
  puts "  - get_5day_forecast: Get 5-day forecast for a city"
  puts "  - get_weather_by_coordinates: Get weather by latitude and longitude"
  mcp.run
end
