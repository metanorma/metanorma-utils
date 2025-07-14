require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Utils do
  it "normalises anchors" do
    expect(Metanorma::Utils.to_ncname("/:ab")).to eq "__ab"
    expect(Metanorma::Utils.to_ncname("Löwe")).to eq "Löwe"
  end

  it "sets metanorma IDs if not provided" do
    uuid = /^_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
    expect(Metanorma::Utils.anchor_or_uuid)
      .to match (uuid)
    expect(Metanorma::Utils.anchor_or_uuid(Dummy.new(nil)))
      .to match (uuid)
    expect(Metanorma::Utils.anchor_or_uuid(Dummy.new("")))
      .to match (uuid)
    expect(Metanorma::Utils.anchor_or_uuid(Dummy.new("A"))).to eq "A"
  end

  it "generates XML snippets from Asciidoctor" do
    input = <<~'INPUT'
      <A> &#150;
    INPUT

    doc = (Asciidoctor::Document.new input.lines,
                                     { standalone: false }).parse
    out = Metanorma::Utils.noko do |xml|
      xml << doc.blocks.first.content
    end
    expect(out).to be_equivalent_to <<~OUTPUT
      &lt;A&gt; 
    OUTPUT
    out = Metanorma::Utils.noko_html do |xml|
      xml << doc.blocks.first.content
    end
    expect(out.join).to be_equivalent_to <<~OUTPUT
      &lt;A&gt; 
    OUTPUT
  end

  it "wraps an Asciidoctor node in paragraph" do
    input = <<~'INPUT'
      NOTE: XYZ
    INPUT
    input2 = <<~'INPUT'
      ====
      A

      B
      ====
    INPUT

    doc = (Asciidoctor::Document.new input.lines,
                                     { standalone: false }).parse
    doc2 = (Asciidoctor::Document.new input2.lines,
                                      { standalone: false }).parse

    out = Metanorma::Utils.noko do |xml|
      Metanorma::Utils.wrap_in_para(doc.blocks.first, xml)
    end
    expect(out).to be_equivalent_to <<~OUTPUT
      <p>XYZ</p>
    OUTPUT
    out = Metanorma::Utils.noko do |xml|
      Metanorma::Utils.wrap_in_para(doc2.blocks.first, xml)
    end
    expect(out).to be_equivalent_to <<~OUTPUT
      <div class="paragraph"><p>A</p></div><div class="paragraph"><p>B</p></div>
    OUTPUT
  end

  it "deals with eoln in different scripts" do
    input = %w(A <em>B</em> C)
    expect(Metanorma::Utils.line_sanitise(input)).to be_equivalent_to [
      "A ", "<em>B</em> ", "C"
    ]
    input = %w(す <em>る</em> 場)
    expect(Metanorma::Utils.line_sanitise(input)).to be_equivalent_to [
      "す", "<em>る</em>", "場"
    ]
    input = ["す", "<em>る</em>", "場", ""]
    expect(Metanorma::Utils.line_sanitise(input)).to be_equivalent_to [
      "す", "<em>る</em>", "場", ""
    ]
  end

  it "applies namespace to xpath" do
    expect(Metanorma::Utils.ns("//ab/Bb/c1-d[ancestor::c][d = 'x'][e/f]"))
      .to be_equivalent_to("//xmlns:ab/xmlns:Bb/xmlns:c1-d[ancestor::xmlns:c]" \
                           "[xmlns:d = 'x'][xmlns:e/xmlns:f]")
  end

  it "converts HTML escapes to hex" do
    expect(Metanorma::Utils.numeric_escapes("A&eacute;B"))
      .to be_equivalent_to "A&#xe9;B"
    expect(Metanorma::Utils.numeric_escapes("A<X>&eacute;</X>B"))
      .to be_equivalent_to "A<X>&#xe9;</X>B"
  end

  it "case transforms XML snippets" do
    expect(Metanorma::Utils
      .case_transform_xml("Title <span class='abc'>abc</span> title", :upcase))
      .to be_equivalent_to 'TITLE <span class="abc">ABC</span> TITLE'
  end

  it "detects GUID anchors" do
    expect(Metanorma::Utils
      .guid_anchor?("_78e83945-77cf-4330-b804-19ba4f387f51"))
      .to be_equivalent_to true
    expect(Metanorma::Utils
      .guid_anchor?("_78e83945-77cf-4330-b804-19ba4f387f512"))
      .to be_equivalent_to false
  end

  it "generates content hash" do
    input = <<~INPUT
      <metanorma>
      <a>
        <b>C</b>
      </a>
      <a>C</a>
      </metanorma>
    INPUT
    xml = Nokogiri::XML(input)
    expect(Metanorma::Utils.contenthash(xml.at("//a[1]")))
      .to be_equivalent_to "_acf23073-0e6b-9e99-5285-032c2dd00d0c"
    expect(Metanorma::Utils.contenthash(xml.at("//a[2]")))
      .to be_equivalent_to "_49246c6e-cf2b-9326-e13f-e6d0cf905178"
  end

  it "uses add_first_child" do
    input = <<~INPUT
      <metanorma>
      <a/>
      <b>C</b>
      <c><d/></c>
      </metanorma>
    INPUT
    xml = Nokogiri::XML(input)
    xml.at("//a").add_first_child("<x>A</x>")
    xml.at("//b").add_first_child("<x>B</x>")
    xml.at("//c").add_first_child("<x>C</x>")
    expect(xml.root.to_xml)
      .to be_equivalent_to <<~OUTPUT
       <metanorma>
       <a><x>A</x></a>
       <b><x>B</x>C</b>
       <c><x>C</x><d/></c>
       </metanorma>
    OUTPUT
  end
end
