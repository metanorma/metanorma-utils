require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end
require "rspec/matchers"
require "equivalent-xml"
require "metanorma-utils"
require "canon"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

class Dummy
  attr_accessor :id, :docfile

  def initialize(id = nil)
    @id = id
  end

  def attr(elem)
    case elem
    when "docfile" then @docfile
    end
  end
end

HTML_HDR = <<~HTML.freeze
  <meta charset="UTF-8"/>
  <style> pre { white-space: pre-wrap; }
  thead th { font-weight: bold; background-color: aqua; }
  .severity0 { font-weight: bold; background-color: lightpink }
  .severity1 { font-weight: bold; }
  .severity2 { }
  .severity3 { font-style: italic; color: grey; }
   </style>
HTML

TBL_HDR = <<~HTML.freeze
  <thead><th width="5%">Line</th><th width="20%">ID</th>
  <th width="30%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
HTML

def break_up_test(str)
  HTMLEntities.new.encode(Metanorma::Utils
        .break_up_long_str(str), :hexadecimal)
end
