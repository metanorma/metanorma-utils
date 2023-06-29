require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Utils do
  it "has a version number" do
    expect(Metanorma::Utils::VERSION).not_to be nil
  end

  it "capitalises" do
    expect(Metanorma::Utils.strict_capitalize_phrase("ABC def gHI"))
      .to eq "ABC Def GHI"
    expect(Metanorma::Utils.strict_capitalize_first("aBC def gHI"))
      .to eq "ABC def gHI"
  end

  it "converts OS-specific external path" do
    pwd = if !!((RUBY_PLATFORM =~ /(win|w)(32|64)$/) ||
                 (RUBY_PLATFORM =~ /mswin|mingw/))
            `echo %cd%`
          else `pwd`
          end
    expect(Metanorma::Utils.external_path(FileUtils.pwd.strip)).to eq pwd.strip
  end

  it "applies Asciidoctor substitutions" do
    expect(Metanorma::Utils.asciidoc_sub("A -- B", "html"))
      .to eq "A&#8201;&#8212;&#8201;B"
    expect(Metanorma::Utils.asciidoc_sub("*A* stem:[x]", "html"))
      .to eq "<strong>A</strong> \\$x\\$"
  end

  it "finds file path of docfile" do
    d = Dummy.new
    expect(Metanorma::Utils.localdir(d)).to eq "./"
    d.docfile = "spec/utils_spec.rb"
    expect(Metanorma::Utils.localdir(d)).to eq "spec/"
  end

  it "applies smart formatting" do
    expect(Metanorma::Utils.smartformat("A - B A -- B A--B '80s '80' <A>"))
      .to eq "A — B A — B A—B ’80s ‘80’ &lt;A&gt;"
  end

  it "applies en-dash normalisation" do
    a = Nokogiri::XML(<<~INPUT)
      <container>
      <a>A -- B A - B</a>
      <b>A--B</b>
      </container>
    INPUT
    Metanorma::Utils.endash_date(a)
    expect(a.to_xml).to be_equivalent_to <<~OUTPUT
          <?xml version="1.0"?>
      <container><a>A&#x2013;B A&#x2013;B</a><b>A&#x2013;B</b></container>
    OUTPUT
  end

  it "sets hash values by dotted key path" do
    a = {}
    a = Metanorma::Utils.set_nested_value(a, ["X"], "x")
    a = Metanorma::Utils.set_nested_value(a, ["X1"], 9)
    a = Metanorma::Utils.set_nested_value(a, ["X2"], [3])
    a = Metanorma::Utils.set_nested_value(a, ["X3"], { "a" => "b" })
    expect(a.to_s).to be_equivalent_to <<~OUTPUT
      {"X"=>"x", "X1"=>9, "X2"=>[3], "X3"=>{"a"=>"b"}}
    OUTPUT
    a = Metanorma::Utils.set_nested_value(a, ["X2"], 4)
    a = Metanorma::Utils.set_nested_value(a, ["X1"], 4)
    expect(a.to_s).to be_equivalent_to <<~OUTPUT
      {"X"=>"x", "X1"=>[9, 4], "X2"=>[3, 4], "X3"=>{"a"=>"b"}}
    OUTPUT
    a = Metanorma::Utils.set_nested_value(a, ["X2", "A"], 5)
    a = Metanorma::Utils.set_nested_value(a, ["X2a"], [])
    a = Metanorma::Utils.set_nested_value(a, ["X2a", "A"], 6)
    a = Metanorma::Utils.set_nested_value(a, ["X4", "A"], 10)
    a = Metanorma::Utils.set_nested_value(a, ["X3", "A"], 7)
    a = Metanorma::Utils.set_nested_value(a, ["X3", "a"], 8)
    a = Metanorma::Utils.set_nested_value(a, ["X1", "a"], 11)
    expect(a.to_s).to be_equivalent_to <<~OUTPUT
      {"X"=>"x", "X1"=>[9, 4, {"a"=>11}], "X2"=>[3, 4, {"A"=>5}], "X3"=>{"a"=>["b", 8], "A"=>7}, "X2a"=>[{"A"=>6}], "X4"=>{"A"=>10}}
    OUTPUT
  end

  it "maps languages to scripts" do
    expect(Metanorma::Utils.default_script("hi")).to eq "Deva"
    expect(Metanorma::Utils.rtl_script?(Metanorma::Utils.default_script("el")))
      .to eq false
    expect(Metanorma::Utils.rtl_script?(Metanorma::Utils.default_script("fa")))
      .to eq true
  end

  # not testing Asciidoctor log extraction here
  it "generates log" do
    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <a>
      <b>
      c
      </b></a></xml>
    INPUT
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", nil, "Message 1")
    log.add("Category 1", "node", "Message 2")
    log.add("Category 2", xml.at("//xml/a/b"), "Message 3")
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to eq <<~OUTPUT
      log.txt errors


      == Category 1

      (): Message 1
      (node): Message 2


      == Category 2

      (XML Line 000003): Message 3
      	<b>
      	c
      	</b>
    OUTPUT
  end

  it "deals with illegal characters in log" do
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", nil, "é\xc2")
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to eq <<~OUTPUT
      log.txt errors


      == Category 1

      (): é�
    OUTPUT
  end

  it "deals with Mathml in log" do
    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <a>
      The number is <stem>
      <MathML xmlns="b">1</MathML>
      <latexmath>\\1</latexmath>
      </stem></a></xml>
    INPUT
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    log.add("Category 2", xml.at("//xml/a"), "Message 3")
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      log.txt errors


      == Category 2


      (XML Line 000002): Message 3
      <a>
      The number is <latexmath>\\1</latexmath></a>
    OUTPUT
  end

  it "parses CSV" do
    expect(Metanorma::Utils.csv_split("A;'B;C'")).to eq ["A", "'B", "C'"]
    expect(Metanorma::Utils.csv_split('A;"B;C"')).to eq ["A", "B;C"]
    expect(Metanorma::Utils.csv_split('A; "B;C"')).to eq ["A", "B;C"]
    expect(Metanorma::Utils.csv_split('A; "B;C"', ",")).to eq ['A; "B;C"']
    expect(Metanorma::Utils.csv_split('A, "B,C"', ",")).to eq ["A", "B,C"]
  end

  it "parses attributes from definition list" do
    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <dummy/>
      <dl>
       <dt>attr1</dt><dd>value1</dd>
       <dt>attr2</dt><dd><p>value1</p><p>value cont</p></dd>
      </xml>
    INPUT
    Metanorma::Utils.dl_to_attrs(xml.at("//dummy"), xml.at("//dl"), "attr1")
    Metanorma::Utils.dl_to_attrs(xml.at("//dummy"), xml.at("//dl"), "attr2")
    expect(xml.to_xml).to be_equivalent_to <<~OUTPUT
      <xml>
       <dummy attr1="value1" attr2="value1"/>
       <dl>
        <dt>attr1</dt><dd>value1</dd>
        <dt>attr2</dt><dd><p>value1</p><p>value cont</p></dd>
       </dl>
       </xml>
    OUTPUT
  end

  it "parses attributes from definition list" do
    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <dummy/>
      <dl>
       <dt>attr1</dt><dd>value1</dd>
       <dt>attr2</dt><dd><p>value1</p><p>value cont</p></dd>
      </xml>
    INPUT
    Metanorma::Utils.dl_to_attrs(xml.at("//dummy"), xml.at("//dl"), "attr1")
    Metanorma::Utils.dl_to_attrs(xml.at("//dummy"), xml.at("//dl"), "attr2")
    expect(xml.to_xml).to be_equivalent_to <<~OUTPUT
      <xml>
       <dummy attr1="value1" attr2="value1"/>
       <dl>
        <dt>attr1</dt><dd>value1</dd>
        <dt>attr2</dt><dd><p>value1</p><p>value cont</p></dd>
       </dl>
       </xml>
    OUTPUT
  end

  it "parses elements from definition list" do
    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <dummy>
        <attr2>A</attr2>
        <attr3>A</attr3>
        <attr2>A</attr2>
      </dummy>
      <dl>
       <dt>attr1</dt><dd>value1</dd>
       <dt>attr2</dt><dd><p>value1</p><p>value cont</p></dd>
      </dl>
      <dummy1/>
      </xml>
    INPUT
    Metanorma::Utils.dl_to_elems(xml.at("//dummy1"), xml.at("//dummy"),
                                 xml.at("//dl"), "attr1")
    Metanorma::Utils.dl_to_elems(xml.at("//dummy1"), xml.at("//dummy"),
                                 xml.at("//dl"), "attr2")
    expect(xml.to_xml).to be_equivalent_to <<~OUTPUT
      <xml>
       <dummy>
         <attr2>A</attr2>
         <attr3>A</attr3>
         <attr2>A</attr2><attr2><p>value1</p><p>value cont</p></attr2>
       </dummy>
       <dl>
        <dt>attr1</dt>
        <dt>attr2</dt>
       </dl>
       <dummy1/><attr1>value1</attr1>
       </xml>
    OUTPUT
  end
end
