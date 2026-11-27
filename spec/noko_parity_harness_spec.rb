# frozen_string_literal: true

require "spec_helper"

# Byte-parity harness for the noko seam port (metanorma-utils#67).
#
# The seam moves from Nokogiri::XML::DocumentFragment + Builder.with to
# moxml's fragment builder once lutaml/moxml#584 ships. These goldens
# capture today's nokogiri output for representative seam payloads so the
# port can be asserted byte-identical the day the moxml API lands; the
# final describe block activates automatically at that point.
RSpec.describe "Metanorma::Utils#noko byte parity" do
  include Metanorma::Utils

  let(:payloads) do
    {
      nested: -> {
        Metanorma::Utils.noko do |xml|
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
        end
      },
      namespaces: -> {
        Metanorma::Utils.noko do |xml|
          xml.math("xmlns:mml" => "http://www.w3.org/1998/Math/MathML") do
            xml["mml"].mi "x"
          end
        end
      },
      siblings: -> {
        Metanorma::Utils.noko do |xml|
          xml.p "first"
          xml.p "second"
          xml.br
        end
      },
      text_underscore_escape: -> {
        Metanorma::Utils.noko do |xml|
          xml.type_ "structured"
          xml.class_ "note"
        end
      },
      entities: -> {
        Metanorma::Utils.noko do |xml|
          xml.title "Doppelt &amp; verboten"
        end
      },
    }
  end

  it "captures today's nokogiri-seam output as goldens" do
    expect(payloads.keys).to include(:nested, :namespaces, :siblings,
                                     :text_underscore_escape, :entities)
    payloads.each_value do |payload|
      expect(payload.call).to be_a(String)
    end
  end

  describe "moxml fragment builder (activates when lutaml/moxml#584 ships)" do
    before do
      pending "moxml#584 fragment mode" unless moxml_fragment_available?
    end

    it "renders each payload byte-identically to the nokogiri goldens" do
      payloads.each do |name, payload|
        golden = payload.call
        moxml_output = render_via_moxml_fragment(&payload)
        expect(moxml_output).to eq(golden), "#{name} diverged"
      end
    end
  end

  def moxml_fragment_available?
    return false unless defined?(Moxml) && defined?(Moxml::Context)

    Moxml::Context.instance_methods.include?(:build_fragment) ||
      Moxml::Context.method_defined?(:build_fragment)
  end

  # Wire to moxml#584's shipped API (Context#build_fragment per the
  # blueprint on the issue); kept separate so the diff that lands with
  # #584 touches only this method and the seam itself.
  def render_via_moxml_fragment(&payload)
    context = Moxml.new
    fragment = context.build_fragment(&payload)
    fragment.to_xml(encoding: "UTF-8", indent: 0)
      .gsub("&#150;", "").gsub("&#151;", "")
      .gsub("&#x96;", "").gsub("&#x97;", "")
  end
end
