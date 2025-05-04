#!/usr/bin/env ruby
# weather_api_client_env.rb
#
# This client demonstrates the usage of the weather API server with environment file.
# It connects to weather_api_server_env.rb which uses .env file for configuration.
#
# Usage:
#   ruby weather_api_client_env.rb

require_relative '../../lib/mcp/client/stdio'
require 'json'

# サーバーに接続（環境変数版のサーバーを使用）
MCP::Client::Stdio.connect(['ruby', 'weather_api_server_env.rb']) do |client|
  # クライアントを初期化
  client.initialize!
  
  # 利用可能なツールを確認
  tools = client.list_tools
  puts "=== Available Weather API Tools ==="
  tools.each do |tool|
    puts "- #{tool.name}"
  end
  puts
  
  # 現在の天気を取得
  puts "=== Current Weather ==="
  cities = ["Tokyo", "New York", "London", "Paris"]
  
  cities.each do |city|
    result_json = client.call_tool(:get_forecast, arguments: { city: city })
    result = JSON.parse(result_json)
    
    if result['error']
      puts "#{city}: #{result['error']}"
    else
      puts "\n#{result['city']}, #{result['country']}:"
      puts "  Temperature: #{result['temperature']}°C (Feels like: #{result['feels_like']}°C)"
      puts "  Conditions: #{result['conditions']}"
      puts "  Humidity: #{result['humidity']}%"
      puts "  Wind Speed: #{result['wind_speed']} m/s"
      puts "  Pressure: #{result['pressure']} hPa"
    end
  end
  
  # 5日間の天気予報を取得
  puts "\n=== 5-Day Forecast for Tokyo ==="
  forecast_json = client.call_tool(:get_5day_forecast, arguments: { city: "Tokyo" })
  forecast = JSON.parse(forecast_json)
  
  if forecast['error']
    puts forecast['error']
  else
    puts "#{forecast['city']}, #{forecast['country']}:"
    forecast['forecasts'].each do |day|
      puts "\n  #{day['date']}:"
      puts "    Temperature: #{day['temperature']}°C"
      puts "    Conditions: #{day['conditions']}"
      puts "    Humidity: #{day['humidity']}%"
      puts "    Wind Speed: #{day['wind_speed']} m/s"
    end
  end
  
  # 座標から天気を取得
  puts "\n=== Weather by Coordinates ==="
  # 富士山の座標
  coords_json = client.call_tool(:get_weather_by_coordinates, arguments: { lat: 35.3606, lon: 138.7274 })
  coords_result = JSON.parse(coords_json)
  
  if coords_result['error']
    puts coords_result['error']
  else
    puts "Location: #{coords_result['location']}"
    puts "Coordinates: #{coords_result['coordinates']['lat']}, #{coords_result['coordinates']['lon']}"
    puts "Temperature: #{coords_result['temperature']}°C"
    puts "Conditions: #{coords_result['conditions']}"
    puts "Humidity: #{coords_result['humidity']}%"
    puts "Wind Speed: #{coords_result['wind_speed']} m/s"
  end
end
