#!/usr/bin/env ruby
# weather_demo_client.rb
#
# This is a simple demonstration client for the weather MCP server.
# It connects to the weather_demo_server.rb and requests mock weather data.
#
# Usage:
#   ruby weather_demo_client.rb

require_relative '../../lib/mcp/client/stdio'
require 'json'

# サーバーに接続
MCP::Client::Stdio.connect(['ruby', 'weather_demo_server.rb']) do |client|
  # クライアントを初期化
  client.initialize!
  
  # 利用可能なツールを確認
  tools = client.list_tools
  puts "=== Available Weather Tools ==="
  tools.each do |tool|
    puts "- #{tool.name}: #{tool.description}"
  end
  puts
  
  # いくつかの都市の天気予報を取得
  cities = ["Tokyo", "New York", "London", "Sydney"]
  
  puts "=== Weather Forecasts ==="
  cities.each do |city|
    begin
      forecast_json = client.call_tool(:get_forecast, arguments: { city: city })
      forecast = JSON.parse(forecast_json)
      
      puts "\n#{city}:"
      puts "  Temperature: #{forecast['temperature']}°C"
      puts "  Conditions: #{forecast['conditions']}"
      puts "  Humidity: #{forecast['humidity']}%"
      puts "  Wind Speed: #{forecast['wind_speed']} km/h"
      puts "  Summary: #{forecast['forecast']}"
    rescue => e
      puts "Error getting forecast for #{city}: #{e.message}"
    end
  end
end
