# frozen_string_literal: true

require "spec_helper"
require "moxml"
require "nokogiri"

# Semantic-equivalence harness for the noko seam port
# (metanorma-utils#67).
#
# The seam moved from Nokogiri::XML::DocumentFragment + Builder.with to
# moxml's fragment builder (lutaml/moxml#584, shipped in 0.6.20). The
# contract is DOM equivalence, not byte parity: nokogiri's serialization
# is not golden — <br></br> and <br/> parse to the same tree, and every
# consumer of the seam's output parses trees. Each payload asserts that
# the moxml seam's output canonically equals the nokogiri reference.
RSpec.describe "Metanorma::Utils#noko semantic parity" do
  NOKOHEAD = <<~HERE
    <!DOCTYPE html SYSTEM
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head> <title></title> <meta charset="UTF-8" /> </head>
    <body> </body> </html>
  HERE

  # Each payload is the seam block. The reference run executes it
  # through the nokogiri seam; the candidate through the moxml seam.
  let(:payloads) do
    {
      nested: ->(xml) {
        xml.table do
          xml.thead do
            xml.tr do
              xml.th "Clause", align: "center"
              xml.th "Requirement"
            end
          end
          xml.tbody do
            xml.tr do
              xml.td "1"
              xml.td "A & B < C > D"
            end
          end
        end
      },
      siblings: ->(xml) {
        xml.p "first"
        xml.p "second"
        xml.br
      },
      text_underscore_escape: ->(xml) {
        xml.type_ "structured"
        xml.class_ "note"
      },
      entities: ->(xml) {
        xml.title "Doppelt &amp; verboten"
      },
      namespaced: ->(xml) {
        xml.math("xmlns:mml" => "http://www.w3.org/1998/Math/MathML") do
          xml["mml"].mi "x"
        end
      },
    }
  end

  it "exercises every representative payload through both seams" do
    expect(payloads.keys).to include(:nested, :namespaced, :siblings,
                                     :text_underscore_escape, :entities)
    payloads.each_value do |payload|
      expect(nokogiri_seam(payload)).to be_a(String)
      expect(moxml_seam(payload)).to be_a(String)
    end
  end

  describe "moxml fragment seam (lutaml/moxml#584, shipped 0.6.20)" do
    it "renders each payload DOM-equivalent to the nokogiri reference" do
      payloads.each do |name, payload|
        reference = nokogiri_seam(payload)
        candidate = moxml_seam(payload)
        expect(canonical_tree(candidate))
          .to eq(canonical_tree(reference)), "#{name} diverged semantically"
      end
    end

    it "emits well-formed XML for every payload" do
      payloads.each_value do |payload|
        # Fragment output is multi-root by contract; wrap to parse.
        expect { Moxml.parse("<w>\#{moxml_seam(payload)}</w>") }
          .not_to raise_error
      end
    end
  end

  # The nokogiri seam, as it stood before the port (shared scaffold,
  # fragment off it, AS_XML serialization, the entity gsub window).
  def nokogiri_seam(payload)
    template = Nokogiri::XML.parse(NOKOHEAD)
    fragment = Nokogiri::XML::DocumentFragment.new(template)
    Nokogiri::XML::Builder.with fragment, &payload
    fragment.to_xml(encoding: "UTF-8", indent: 0,
                    save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      .gsub("&#150;", "").gsub("&#151;", "")
      .gsub("&#x96;", "").gsub("&#x97;", "")
  end

  # The moxml fragment seam (shipped API: Moxml.fragment per
  # lutaml/moxml#584 in 0.6.20), same entity window.
  def moxml_seam(payload)
    builder = Moxml.fragment(:leptris)
    builder.build(&payload)
    builder.to_xml
      .gsub("&#150;", "").gsub("&#151;", "")
      .gsub("&#x96;", "").gsub("&#x97;", "")
  end

  # Canonical form for DOM-equivalence: parsed, comments dropped, each
  # element's attributes sorted and children in document order —
  # engine serialization choices (empty-element style, quoting,
  # indentation) are irrelevant by design.
  def canonical_tree(xml)
    # Seam output is a FRAGMENT (multiple roots by contract): wrap in a
    # synthetic root so the parse sees one document, then compare the
    # wrapped children.
    doc = Moxml.parse("<canonical-wrap>\#{xml}</canonical-wrap>".gsub("\u0000", ""))
    out = []
    walk = lambda do |node|
      case node.node_type
      when :element
        attrs = node.attributes.map { |a| [a.name, a.value] }.sort
        out << "<\#{node.name} \#{attrs.inspect}>"
        node.children.each { |c| walk.call(c) }
        out << "</\#{node.name}>"
      when :text, :cdata
        out << node.content
      end
    end
    root = doc.root
    root.children.each { |c| walk.call(c) }
    out.join("|")
  end
end
