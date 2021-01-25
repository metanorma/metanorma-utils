require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end
require "rspec/matchers"
require "equivalent-xml"
require "metanorma-utils"

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
  attr_accessor :id
  attr_accessor :docfile
  def initialize(id = nil)
    @id = id
  end

  def attr(x)
    case x
    when "docfile" then @docfile
    end
  end
end

