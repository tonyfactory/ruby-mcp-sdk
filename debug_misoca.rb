#!/usr/bin/env ruby
# frozen_string_literal: true

require 'oauth2'
require 'dotenv'
require 'json'
require 'fileutils'

# Load environment variables
Dotenv.load

# 認証情報の確認
puts "環境変数チェック:"
puts "MISOCA_APPLICATION_ID: #{ENV['MISOCA_APPLICATION_ID'] ? '設定済み' : '未設定'}"
puts "MISOCA_APP_SECRET_KEY: #{ENV['MISOCA_APP_SECRET_KEY'] ? '設定済み' : '未設定'}"
puts "MISOCA_REDIRECT_URI: #{ENV['MISOCA_REDIRECT_URI'] ? ENV['MISOCA_REDIRECT_URI'] : '未設定'}"

# OAuth2クライアントを作成
def create_oauth_client
  OAuth2::Client.new(
    ENV['MISOCA_APPLICATION_ID'],
    ENV['MISOCA_APP_SECRET_KEY'],
    site: 'https://app.misoca.jp',
    authorize_url: '/oauth2/authorize',
    token_url: '/oauth2/token'
  )
end

# 認証URLを取得
def get_auth_url
  client = create_oauth_client
  redirect_uri = ENV['MISOCA_REDIRECT_URI'] || 'http://localhost:9393/callback'
  client.auth_code.authorize_url(redirect_uri: redirect_uri, scope: 'read')
end

# アクセストークンを取得
def get_access_token(code)
  client = create_oauth_client
  redirect_uri = ENV['MISOCA_REDIRECT_URI'] || 'http://localhost:9393/callback'
  begin
    token = client.auth_code.get_token(code, redirect_uri: redirect_uri)
    save_token(token)
    puts "アクセストークン: #{token.token}"
    puts "リフレッシュトークン: #{token.refresh_token}"
    puts "有効期限: #{Time.at(token.expires_at)}"
    return token
  rescue => e
    puts "エラー: #{e.message}"
    puts e.backtrace
    return nil
  end
end

# トークンを保存
def save_token(token)
  env_file = './.env'
  env_content = File.exist?(env_file) ? File.read(env_file) : ""

  # 環境変数を更新または追加
  {
    'MISOCA_ACCESS_TOKEN' => token.token,
    'MISOCA_REFRESH_TOKEN' => token.refresh_token,
    'MISOCA_TOKEN_EXPIRES_AT' => token.expires_at.to_s
  }.each do |key, value|
    if env_content.match?(/^#{key}=.*$/)
      env_content.gsub!(/^#{key}=.*$/, "#{key}=#{value}")
    else
      env_content += "\n#{key}=#{value}"
    end
  end

  # ファイルに保存
  begin
    File.write(env_file, env_content)
    puts ".envファイルに保存しました"
  rescue => e
    puts "ファイル保存エラー: #{e.message}"
    puts "現在のディレクトリ: #{Dir.pwd}"
    puts "ファイルパス: #{File.expand_path(env_file)}"
  end
end

# 請求書一覧を取得
def list_invoices
  # アクセストークンを確認
  unless ENV['MISOCA_ACCESS_TOKEN']
    puts "アクセストークンがありません。先に認証してください。"
    return
  end

  # OAuth2::AccessTokenを作成
  token = OAuth2::AccessToken.new(
    create_oauth_client,
    ENV['MISOCA_ACCESS_TOKEN'],
    refresh_token: ENV['MISOCA_REFRESH_TOKEN'],
    expires_at: ENV['MISOCA_TOKEN_EXPIRES_AT']&.to_i
  )

  begin
    # 請求書一覧を取得
    response = token.get('/v3/invoices')
    data = JSON.parse(response.body)
    
    if data['invoices']&.any?
      puts "#{data['invoices'].size}件の請求書が見つかりました:"
      data['invoices'].each do |invoice|
        puts "ID: #{invoice['id']}, タイトル: #{invoice['title']}"
      end
    else
      puts "請求書が見つかりませんでした。"
    end
  rescue => e
    puts "APIエラー: #{e.message}"
    puts e.backtrace
  end
end

# メイン処理
puts "このデバッグスクリプトは以下の操作を行います:"
puts "1. 認証URL取得"
puts "2. アクセストークン取得 (コードが必要)"
puts "3. 請求書一覧取得"
print "実行する操作を選択してください (1-3): "
choice = gets.chomp.to_i

case choice
when 1
  puts "認証URL: #{get_auth_url}"
when 2
  print "認証コードを入力してください: "
  code = gets.chomp
  get_access_token(code)
when 3
  list_invoices
else
  puts "無効な選択です。"
end
