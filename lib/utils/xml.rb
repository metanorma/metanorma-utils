require "asciidoctor"
require "tempfile"
require "uuidtools"
require "htmlentities"
require "nokogiri"

module Nokogiri
  module XML
    class Node
      def add_first_child(content)
        if children.empty?
          add_child(content)
        else
          children.first.previous = content
        end
        self
      end
    end
  end
end

module Metanorma
  module Utils
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

      # block for processing XML document fragments as XHTML,
      # to allow for HTMLentities
      # Unescape special chars used in Asciidoctor substitution processing
      def noko(_script = "Latn", &block)
        fragment = ::Nokogiri::XML.parse(NOKOHEAD).fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        fragment
          .to_xml(encoding: "UTF-8", indent: 0,
                  save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
          .gsub("&#150;", "\u0096").gsub("&#151;", "\u0097")
          .gsub("&#x96;", "\u0096").gsub("&#x97;", "\u0097")
      end

      # By default, carriage return in source translates to whitespace;
      # but in CJK, it does not.  (Non-CJK text \n CJK)
      def line_sanitise(ret)
        ret.size == 1 and return ret
        (0...(ret.size - 1)).each do |i|
          last = firstchar_xml(ret[i].reverse)
          nextfirst = firstchar_xml(ret[i + 1])
          cjk1 = /#{CJK}/o.match?(last)
          cjk2 = /#{CJK}/o.match?(nextfirst)
          text1 = /[^\p{Z}\p{C}]/.match?(last)
          text2 = /[^\p{Z}\p{C}]/.match?(nextfirst)
          cjk1 && (cjk2 || !text2) and next
          !text1 && cjk2 and next
          ret[i] += " "
        end
        ret
      end

      # need to deal with both <em> and its reverse string, >me<
      def firstchar_xml(line)
        m = /^([<>][^<>]+[<>])*(.)/.match(line) or return ""
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
        xpath.gsub(%r{/([a-zA-Z])}, "/xmlns:\\1")
          .gsub(%r{::([a-zA-Z])}, "::xmlns:\\1")
          .gsub(%r{\[([a-zA-Z][a-z0-9A-Z@/-]* ?=)}, "[xmlns:\\1")
          .gsub(%r{\[([a-zA-Z][a-z0-9A-Z@/-]*[/\[\]])}, "[xmlns:\\1")
      end

      def numeric_escapes(xml)
        c = HTMLEntities.new
        xml.split(/(&[^ \r\n\t#&;]+;)/).map do |t|
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
    end
  end
end
