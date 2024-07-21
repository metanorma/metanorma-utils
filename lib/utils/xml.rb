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
      def attr_code(attributes)
        attributes.compact.transform_values do |v|
          v.is_a?(String) ? HTMLEntities.new.decode(v) : v
        end
      end

      def to_ncname(tag, asciionly: true)
        asciionly and tag = HTMLEntities.new.encode(tag, :basic,
                                                    :hexadecimal)
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
      def noko(script = "Latn", &block)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        fragment = doc.fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        eoln = %w(Hans Hant Jpan).include?(script) ? "" : " "
        fragment.to_xml(encoding: "US-ASCII", indent: 0,
                        save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
          .lines.map do |l|
          l.gsub(/>\n$/, ">").gsub(/\n$/m, eoln).gsub("&#150;", "\u0096")
            .gsub("&#151;", "\u0097").gsub("&#x96;", "\u0096")
            .gsub("&#x97;", "\u0097")
        end
      end

      def noko(_script = "Latn", &block)
        fragment = ::Nokogiri::XML.parse(NOKOHEAD).fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        ret = fragment
          .to_xml(encoding: "UTF-8", indent: 0,
                  save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
          .lines.map do |l|
            l.rstrip.gsub("&#150;", "\u0096").gsub("&#151;", "\u0097")
              .gsub("&#x96;", "\u0096").gsub("&#x97;", "\u0097")
          end
        line_sanitise(ret)
      end

      # By default, carriage return in source translates to whitespace;
      # but in CJK, it does not.  We don't want carriage returns in the final
      # output because of CJK complications
      def line_sanitise(ret)
        ret.size == 1 and return ret
        (0...ret.size).each do |i|
          last = firstchar_xml(ret[i].reverse)
          nextfirst = firstchar_xml(ret[i + 1])
          /#{CJK}/o.match?(last) && /#{CJK}/o.match?(nextfirst) or
            ret[i] += " "
        end
        ret
      end

      def firstchar_xml(line)
        m = /^(<[^>]+>)*(.)/.match(line) or return ""
        m[2]
      end

      def noko_html(&block)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        fragment = doc.fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        fragment.to_xml(encoding: "UTF-8", indent: 0,
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

      # if the contents of node are blocks, output them to out;
      # else, wrap them in <p>
      def wrap_in_para(node, out)
        if node.blocks? then out << node.content
        else
          out.p { |p| p << node.content }
        end
      end

      # all element/attribute pairs that are ID anchors in Metanorma
      def anchor_attributes
        [%w[* id], %w[* bibitemid], %w[review from],
         %w[review to], %w[index to], %w[xref target],
         %w[callout target], %w[location target]]
      end

      # convert definition list term/value pair into Nokogiri XML attribute
      def dl_to_attrs(elem, dlist, name)
        e = dlist.at("./dt[text()='#{name}']") or return
        val = e.at("./following::dd/p") || e.at("./following::dd") or return
        elem[name] = val.text
      end

      # convert definition list term/value pairs into Nokogiri XML elements
      def dl_to_elems(ins, elem, dlist, name)
        a = elem.at("./#{name}[last()]")
        ins = a if a
        dlist.xpath("./dt[text()='#{name}']").each do |e|
          ins = dl_to_elems1(e, name, ins)
        end
        ins
      end

      def dl_to_elems1(term, name, ins)
        v = term.at("./following::dd")
        e = v.elements and e.size == 1 && e.first.name == "p" and v = e.first
        v.name = name
        ins.next = v
        ins.next
      end

      def case_transform_xml(xml, kase)
        x = Nokogiri::XML("<root>#{xml}</root>")
        x.traverse do |e|
          e.text? or next
          e.replace(e.text.send(kase))
        end
        x.root.children.to_xml
      end

      def guid_anchor?(id)
        /^_[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i
          .match?(id)
      end
    end
  end
end
