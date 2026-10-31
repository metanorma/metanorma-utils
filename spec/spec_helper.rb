require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end
require "rspec/matchers"
require "canon/rspec_matchers"
require "nokogiri"

# metanorma-utils sits below isodoc in the stack, so isodoc's
# canon_html_input_guard cannot be required here. Mirror its XML
# fragment wrapping: canon's strict parser rejects multi-root
# fragments, so wrap both sides in a shared synthetic root.
module Metanorma
  module Utils
    module CanonXmlFragGuard
      ROOT = "canon-xml-frag-root"

      def compute_equivalent(target)
        if @format == :xml
          @expected = wrap(@expected)
          target = wrap(target)
        end
        super(target)
      end

      private

      def wrap(value)
        return value unless value.is_a?(String)
        # XML declarations are legal only at document start; a fragment
        # carrying one blows up the strict wrap parse. Declarations carry
        # no comparison semantics (mirrors isodoc#876).
        value = value.gsub(/<\?xml[^>]*\?>\s*/, "")
        return value if value.include?(ROOT)
        wrapped = "<#{ROOT}>#{value}</#{ROOT}>"
        begin
          Canon::XmlParsing.moxml_context.parse(wrapped, readonly: true, strict: true)
          wrapped
        rescue StandardError
          begin
            Nokogiri::XML(wrapped).to_xml
          rescue StandardError
            wrapped
          end
        end
      end
    end
  end
end
Canon::RSpecMatchers::SerializationMatcher
  .prepend(Metanorma::Utils::CanonXmlFragGuard)
require "metanorma-utils"
require "canon"

Canon::Config.instance.profile = :metanorma

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
  <thead><th width="5%">Line</th><th width="20%">ID</th><th width="10%">Error</th>
  <th width="20%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
HTML

def break_up_test(str)
  HTMLEntities.new.encode(Metanorma::Utils
        .break_up_long_str(str), :hexadecimal)
end
