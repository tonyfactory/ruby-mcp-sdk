# MCP Ruby SDK

Model Context Protocol (MCP) のRuby実装で、RubyアプリケーションがLarge Language Modelsに機能を公開するサーバーとクライアントを作成できるようにします。

## 概要

Model Context Protocolは、アプリケーションがLLMにコンテキストを標準化された方法で提供できるようにし、コンテキスト提供と実際のLLMとのやり取りの関心事を分離します。このRuby SDKはMCP仕様の完全な実装を提供し、以下のことを簡単に行えます：

- 任意のMCPサーバーに接続できるMCPクライアントの構築
- リソース、プロンプト、ツールを公開するMCPサーバーの作成
- stdioやSSEのような標準的なトランスポートの使用
- すべてのMCPプロトコルメッセージとライフサイクルイベントの処理

## インストール

アプリケーションのGemfileに以下の行を追加してください：

```ruby
gem 'mcp'
```

そして以下を実行します：

```bash
bundle install
```

または、自分でインストールする場合：

```bash
gem install mcp
```

## クイックスタート

### シンプルなサーバーの作成

計算機ツールを公開する基本的なMCPサーバーの作成方法：

```ruby
# server.rb
require 'mcp/server/fastmcp'

# MCPサーバーを作成
mcp = MCP::FastMCP.new("Calculator")

# ツールを追加
mcp.tool(:add) do |a, b|
  a + b
end

# サーバーを実行
if __FILE__ == $0
  mcp.run
end
```

### クライアントの作成

MCPサーバーに接続するクライアントの作成方法：

```ruby
# client.rb
require 'mcp/client'
require 'mcp/client/stdio'

# サーバーに接続
MCP::Client::Stdio.connect(['python', 'server.py']) do |client|
  # 接続を初期化
  client.initialize!

  # 利用可能なツールを一覧表示
  tools = client.list_tools
  puts "利用可能なツール: #{tools.map(&:name).join(', ')}"

  # ツールを呼び出す
  result = client.call_tool('add', arguments: { a: 5, b: 3 })
  puts "5 + 3 = #{result}"
end
```

## Misoca API 統合

このSDKでは、Misoca APIを使用して請求書データをClaudeデスクトップから取得できるようになりました。この機能を使用するには、まず以下の手順でMisocaアプリケーションを登録する必要があります。

### Misoca アプリケーション登録

1. Misocaにログインした状態で、[https://app.misoca.jp/oauth2/applications](https://app.misoca.jp/oauth2/applications) にアクセスします
2. 「新しいアプリケーション」ボタンをクリックして、アプリケーション登録画面に進みます
3. 以下の情報を入力します：
   - アプリケーション名: 任意の名前（例: Claude Desktop Integration）
   - リダイレクトURI: `http://localhost:9393/callback`（または任意のコールバックURI）
4. 登録後、アプリケーションIDとシークレットキーが発行されます

### 環境設定

`.env`ファイルを作成し、以下の情報を設定します（`.env.example`からコピーできます）：

```
# Misoca API credentials
MISOCA_APPLICATION_ID=your_application_id
MISOCA_APP_SECRET_KEY=your_app_secret_key
MISOCA_REDIRECT_URI=http://localhost:9393/callback
```

### Misoca API クライアントの使用方法

#### コマンドラインから使用する

```bash
# 認証URLの取得
bundle exec exe/misoca authorize

# 認証コードを使ってトークンを取得
bundle exec exe/misoca callback <authorization_code>

# 請求書一覧の取得
bundle exec exe/misoca list

# 特定の請求書の詳細を取得
bundle exec exe/misoca get <invoice_id>

# 請求書PDFをダウンロード
bundle exec exe/misoca download <invoice_id> [output_path]
```

#### Rubyコードから使用する

```ruby
require 'mcp'
require 'dotenv'

# 環境変数を読み込む
Dotenv.load

# Misocaクライアントを作成
client = MCP::Client::Misoca.new

# 認証URL生成
auth_url = client.authorize_url('read')
puts "認証URL: #{auth_url}"

# 認証コードを使ってトークン取得
token = client.get_access_token(authorization_code)

# 請求書一覧取得
invoices = client.list_invoices
puts "請求書数: #{invoices.size}"

# 特定の請求書の詳細取得
invoice = client.get_invoice(invoice_id)
puts "請求書タイトル: #{invoice['title']}"

# 請求書PDFのダウンロード
pdf_data = client.download_invoice_pdf(invoice_id)
File.binwrite("invoice.pdf", pdf_data)
```

サンプルコードは `examples/misoca_example.rb` を参照してください。

## コアコンセプト

MCPプロトコルは3つのコアプリミティブを定義しています：

### リソース
リソースはサーバーが公開する読み取り専用のデータソースです。静的ファイルや動的コンテンツにすることができます：

```ruby
mcp.resource("config://app") do
  { environment: "production", version: "1.0.0" }.to_json
end

mcp.resource("users://{user_id}/profile") do |user_id|
  # ユーザープロファイルデータを取得して返す
  User.find(user_id).profile.to_json
end
```

### ツール
ツールはLLMがサーバーを通じてアクションを実行できるようにします：

```ruby
mcp.tool(:send_email) do |to, subject, body|
  EmailService.send(to: to, subject: subject, body: body)
  "メールを送信しました"
end
```

### プロンプト
プロンプトはLLMとのやり取りのための再利用可能なテンプレートです：

```ruby
mcp.prompt(:review_code) do |code|
  "このコードをレビューしてフィードバックを提供してください：\n\n#{code}"
end
```

## 高度な機能

### コンテキストサポート

ハンドラー内でサーバーコンテキストにアクセス：

```ruby
mcp.tool(:long_task) do |files, context|
  files.each_with_index do |file, i|
    context.info("#{file}を処理中")
    context.report_progress(i, files.length)
    # ファイルを処理...
  end
  "処理が完了しました"
end
```

### 非同期サポート

RubyのFiberスケジューラーを使用して、すべてのハンドラーを非同期にできます：

```ruby
mcp.tool(:fetch_data) do |url|
  response = Async::HTTP::Internet.new.get(url)
  response.read
end
```

## 例

完全な例については`examples/`ディレクトリを確認してください：

- `calculator_server.rb` - シンプルな計算機サーバー
- `echo_server.rb` - すべてのプリミティブを示すエコーサーバー
- `client_example.rb` - クライアントの使用例
- `misoca_example.rb` - Misoca API クライアントの使用例

## ドキュメント

Model Context Protocolの詳細については、以下を参照してください：

- [Model Context Protocol ドキュメント](https://modelcontextprotocol.io)
- [Model Context Protocol 仕様](https://spec.modelcontextprotocol.io)

Misoca APIの詳細については、以下を参照してください：

- [Misoca API ドキュメント](https://doc.misoca.jp/)
- [Misoca API v3 ドキュメント](https://doc.misoca.jp/v3/)

## コントリビューション

1. フォークする
2. フィーチャーブランチを作成する (`git checkout -b my-new-feature`)
3. 変更をコミットする (`git commit -am 'Add some feature'`)
4. ブランチにプッシュする (`git push origin my-new-feature`)
5. プルリクエストを作成する

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細はLICENSEファイルを参照してください。
