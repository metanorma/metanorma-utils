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
  .severity2 { }  </style>
HTML

TBL_HDR = <<~HTML.freeze
  <thead><th width="5%">Line</th><th width="20%">ID</th>
  <th width="30%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
HTML

def xmlpp(xml)
  xsl = <<~XSL
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
      <xsl:strip-space elements="*"/>
      <xsl:template match="/">
        <xsl:copy-of select="."/>
      </xsl:template>
    </xsl:stylesheet>
  XSL
  Nokogiri::XSLT(xsl).transform(Nokogiri::XML(xml, &:noblanks))
    .to_xml(indent: 2, encoding: "UTF-8")
end

def break_up_test(str)
  HTMLEntities.new.encode(Metanorma::Utils
        .break_up_long_str(str), :hexadecimal)
end
