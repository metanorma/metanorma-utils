require "asciidoctor"
require "tempfile"
require "uuidtools"
require "htmlentities"
require "nokogiri"

module Metanorma
  module Utils
    NAMECHAR = "\u0000-\u002c\u002f\u003a-\u0040\\u005b-\u005e" \
               "\u0060\u007b-\u00b6\u00b8-\u00bf\u00d7\u00f7\u037e" \
               "\u2000-\u200b" \
               "\u200e-\u203e\u2041-\u206f\u2190-\u2bff\u2ff0-\u3000".freeze
    NAMESTARTCHAR = "\\u002d\u002e\u0030-\u0039\u00b7\u0300-\u036f" \
                    "\u203f-\u2040".freeze
    NOKOHEAD = <<~HERE.freeze
      <!DOCTYPE html SYSTEM
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head> <title></title> <meta charset="UTF-8" /> </head>
      <body> </body> </html>
    HERE

    class << self
      def to_ncname(tag, asciionly: true)
        asciionly and tag = HTMLEntities.new.encode(tag, :basic, :hexadecimal)
        start = tag[0]
        ret1 = if %r([#{NAMECHAR}#])o.match?(start)
                 "_"
               else
                 (%r([#{NAMESTARTCHAR}#])o.match?(start) ? "_#{start}" : start)
               end
        ret2 = tag[1..-1] || ""
        (ret1 || "") + ret2.gsub(%r([#{NAMECHAR}#])o, "_")
      end

      def anchor_or_uuid(node = nil)
        uuid = UUIDTools::UUID.random_create
        node.nil? || node.id.nil? || node.id.empty? ? "_#{uuid}" : node.id
      end

      # block for processing XML document fragments as XHTML,
      # to allow for HTMLentities
      # Unescape special chars used in Asciidoctor substitution processing
      def noko(&block)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        fragment = doc.fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        fragment.to_xml(encoding: "US-ASCII", indent: 0,
                        save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
          .lines.map do |l|
          l.gsub(/>\n$/, ">").gsub(/\s*\n$/m, " ").gsub("&#150;", "\u0096")
            .gsub("&#151;", "\u0097").gsub("&#x96;", "\u0096")
            .gsub("&#x97;", "\u0097")
        end
      end

      def noko_html(&block)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        fragment = doc.fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        fragment.to_xml(encoding: "US-ASCII", indent: 0,
                        save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
          .lines.map do |l|
          l.gsub(/\s*\n/, "")
        end
      end

      def to_xhtml_fragment(xml)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        doc.fragment(xml)
      end

      def ns(xpath)
        xpath.gsub(%r{/([a-zA-z])}, "/xmlns:\\1")
          .gsub(%r{::([a-zA-z])}, "::xmlns:\\1")
          .gsub(%r{\[([a-zA-z][a-z0-9A-Z@/-]* ?=)}, "[xmlns:\\1")
          .gsub(%r{\[([a-zA-z][a-z0-9A-Z@/-]*[/\[\]])}, "[xmlns:\\1")
      end

      def numeric_escapes(xml)
        c = HTMLEntities.new
        xml.split(/(&[^ \r\n\t#;]+;)/).map do |t|
          if /^(&[^ \t\r\n#;]+;)/.match?(t)
            c.encode(c.decode(t), :hexadecimal)
          else t
          end
        end.join
      end
    end
  end
end
