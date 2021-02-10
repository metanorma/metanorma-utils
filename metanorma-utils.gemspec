# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
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
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {spec}/*`.split("\n")
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.add_dependency "sterile", "~> 1.0.14"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "nokogiri", "~> 1.10.4"
  spec.add_dependency "asciidoctor", "~> 2.0.0"
  spec.add_dependency "uuidtools"
  spec.add_dependency "mimemagic"
  spec.add_dependency "mime-types"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "rubocop", "= 0.54.0"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "vcr", "~> 5.0.0"
  spec.add_development_dependency "webmock"
end
