# Ruby MCP SDK

RubyによるModel Context Protocol (MCP) サーバーを作成するためのSDKです。

## インストール

アプリケーションのGemfileに以下の行を追加してください：

```ruby
gem 'mcp-ruby-sdk'
```

そして以下を実行します：

```bash
bundle install
```

または、自分でインストールする場合：

```bash
gem install mcp-ruby-sdk
```

## 基本的な使い方

### MCPサーバーの作成

シンプルなMCPサーバーを作成する例：

```ruby
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

## 必要条件

- Ruby 3.1以上

## ドキュメント

Model Context Protocolの詳細については、以下を参照してください：

- [Model Context Protocol ドキュメント](https://modelcontextprotocol.io)
- [Model Context Protocol 仕様](https://spec.modelcontextprotocol.io)

## コントリビューション

1. リポジトリをフォークする
2. フィーチャーブランチを作成する (`git checkout -b my-new-feature`)
3. 変更をコミットする (`git commit -am 'Add some feature'`)
4. ブランチにプッシュする (`git push origin my-new-feature`)
5. プルリクエストを作成する

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は[LICENSE](LICENSE)ファイルを参照してください。