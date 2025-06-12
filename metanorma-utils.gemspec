# coding: utf-8

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "utils/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-utils"
  spec.version       = Metanorma::Utils::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "metanorma-utils "
  spec.description   = <<~DESCRIPTION
    metanorma-utils provides utilities for the Metanorma stack
  DESCRIPTION

  spec.homepage      = "https://github.com/metanorma/metanorma-utils"
  spec.license       = "BSD-2-Clause"

  spec.bindir        = "bin"
  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|bin|.github)/}) \
    || f.match(%r{Rakefile|bin/rspec})
  end
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")

  spec.add_dependency "asciidoctor", ">= 2"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "csv"
  spec.add_dependency "htmlentities", "~> 4.3.4"
  spec.add_dependency "nokogiri", ">= 1.11"
  spec.add_dependency "sterile", "~> 1.0.14"
  spec.add_dependency "uuidtools"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "rubocop", "~> 1"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "xml-c14n"
  # spec.metadata["rubygems_mfa_required"] = "true"
end
