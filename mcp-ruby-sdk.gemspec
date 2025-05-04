# frozen_string_literal: true

require_relative "lib/mcp/version"

Gem::Specification.new do |spec|
  spec.name = "mcp"
  spec.version = MCP::VERSION
  spec.authors = ["MCP Ruby Contributors"]
  spec.email = ["mcpruby@example.com"]

  spec.summary = "Model Context Protocol SDK for Ruby"
  spec.description = "A Ruby implementation of the Model Context Protocol (MCP) for building servers and clients that expose capabilities to Large Language Models."
  spec.homepage = "https://github.com/your-org/ruby-mcp-sdk"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    LICENSE
    README.md
    CHANGELOG.md
  ])
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  # No runtime dependencies needed - using only stdlib

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.18"
  spec.add_development_dependency "minitest-reporters", "~> 1.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-minitest", "~> 0.31"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
end
