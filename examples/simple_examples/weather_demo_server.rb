#!/usr/bin/env ruby
# weather_demo_server.rb
#
# This is a simple demonstration of an MCP weather server using Ruby SDK.
# It returns mock weather data for demo purposes.
#
# Usage:
#   ruby weather_demo_server.rb

require_relative '../../lib/mcp/server/fastmcp'
require 'json'
require 'net/http'
require 'uri'

# MCPサーバーを作成
mcp = MCP::FastMCP.new('weather')

# 天気予報を取得するツール
mcp.tool(:get_forecast) do |city|
  # 実際のAPIではNWS（National Weather Service）を使用しますが、
  # ここではデモ用に模擬データを返します
  temperature = 20 + rand(15)
  conditions = ["sunny", "cloudy", "rainy", "windy"].sample
  
  {
    temperature: temperature,
    conditions: conditions,
    humidity: 45 + rand(40),
    wind_speed: 5 + rand(20),
    forecast: "The weather in #{city} is #{conditions} with a temperature of #{temperature}°C"
  }.to_json
end

# サーバーを実行
if __FILE__ == $0
  puts "Starting Weather Demo Server..."
  puts "This server provides mock weather data for demonstration purposes."
  mcp.run
end
