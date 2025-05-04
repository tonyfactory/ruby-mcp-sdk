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

## ドキュメント

Model Context Protocolの詳細については、以下を参照してください：

- [Model Context Protocol ドキュメント](https://modelcontextprotocol.io)
- [Model Context Protocol 仕様](https://spec.modelcontextprotocol.io)

## コントリビューション

1. フォークする
2. フィーチャーブランチを作成する (`git checkout -b my-new-feature`)
3. 変更をコミットする (`git commit -am 'Add some feature'`)
4. ブランチにプッシュする (`git push origin my-new-feature`)
5. プルリクエストを作成する

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細はLICENSEファイルを参照してください。
