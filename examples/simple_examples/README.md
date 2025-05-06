# Ruby MCP SDK Weather Examples

このディレクトリには、Ruby MCP SDKを使用した天気サーバーの例が含まれています。

## ファイル一覧

1. `weather_demo_server.rb` - モックデータを使用したシンプルな天気デモサーバー
2. `weather_demo_client.rb` - デモサーバー用のクライアント
3. `weather_api_server.rb` - OpenWeatherMap APIを使用した実際の天気サーバー（環境変数版）
4. `weather_api_client.rb` - APIサーバー用のクライアント（環境変数版）
5. `weather_api_server_with_key.rb` - APIキー埋め込み版のサーバー（デモ用）
6. `weather_api_client_simple.rb` - キー埋め込み版サーバー用のクライアント
7. `weather_api_server_env.rb` - .envファイルを使用するサーバー（推奨）
8. `weather_api_client_env.rb` - .envファイル版サーバー用のクライアント

## デモサーバーの使用方法

デモサーバーはモックデータを返すシンプルな実装です：

```bash
# サーバーを起動
ruby weather_demo_server.rb

# 別のターミナルでクライアントを実行
ruby weather_demo_client.rb
```

## API サーバーの使用方法（推奨：.envファイル版）

実際の天気データを取得するには、OpenWeatherMap APIキーが必要です：

1. [OpenWeatherMap](https://openweathermap.org/api) で無料のAPIキーを取得
2. アプリケーションルートの `.env.example` を `.env` にコピーしてAPIキーを設定：

```bash
# プロジェクトルートに移動
cd /path/to/ruby-mcp-sdk

# .env.exampleをコピー
cp .env.example .env

# .envファイルを編集してAPIキーを設定
# OPENWEATHER_API_KEY=your_api_key_here
```

3. サーバーとクライアントを実行：

```bash
# サーバーを起動
ruby weather_api_server_env.rb

# 別のターミナルでクライアントを実行
ruby weather_api_client_env.rb
```

## 機能

### デモサーバー

- `get_forecast`: 指定した都市のモック天気データを返す

### APIサーバー

- `get_forecast`: 指定した都市の現在の天気を取得
- `get_5day_forecast`: 指定した都市の5日間の天気予報を取得
- `get_weather_by_coordinates`: 緯度経度から天気を取得

## 使用例

```ruby
# MCPサーバーとして使用
require_relative 'weather_api_server_env'

# クライアントから呼び出し
client.call_tool(:get_forecast, arguments: { city: "Tokyo" })
client.call_tool(:get_5day_forecast, arguments: { city: "New York" })
client.call_tool(:get_weather_by_coordinates, arguments: { lat: 35.6895, lon: 139.6917 })
```

## セキュリティに関する注意事項

- `.env` ファイルには機密情報（APIキー）が含まれるため、Gitにコミットしないでください
- `.gitignore` ファイルで `.env` を除外しています
- 本番環境では環境変数や安全な設定管理システムを使用してください
- APIキーをソースコードに直接記述することは避けてください

## APIキーの取得

1. [OpenWeatherMap](https://openweathermap.org/api) にアクセス
2. 無料アカウントを作成
3. APIキーを取得（無料プランでも1日1000回まで呼び出し可能）
4. `.env` ファイルにAPIキーを設定
