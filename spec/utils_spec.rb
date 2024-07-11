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
    a = Metanorma::Utils.set_nested_value(a, ["X", "a"], 12)
    expect(a.to_s).to be_equivalent_to <<~OUTPUT
      {"X"=>["x", {"a"=>12}], "X1"=>[9, 4, {"a"=>11}], "X2"=>[3, 4, {"A"=>5}], "X3"=>{"a"=>["b", 8], "A"=>7}, "X2a"=>[{"A"=>6}], "X4"=>{"A"=>10}}
    OUTPUT
  end

  it "maps languages to scripts" do
    expect(Metanorma::Utils.default_script("hi")).to eq "Deva"
    expect(Metanorma::Utils.default_script("tlh")).to eq "Latn"
    expect(Metanorma::Utils.default_script("bg")).to eq "Cyrl"
    expect(Metanorma::Utils.rtl_script?(Metanorma::Utils.default_script("el")))
      .to eq false
    expect(Metanorma::Utils.rtl_script?(Metanorma::Utils.default_script("fa")))
      .to eq true
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

  it "processes XML attributes" do
    ret = Metanorma::Utils.attr_code({ a: 1, b: "&#x65;", c: nil })
    expect(ret).to be_equivalent_to '{:a=>1, :b=>"e"}'
  end

  it "breaks up long strings" do
    expect(break_up_test("http://www.example.com/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/BBBBBBBBBBBBBBBBBBBBBBBBBBBB"))
      .to eq "http://&#x200b;www.example.&#x200b;com/&#x200b;AAAAAAAAAAAAAAAAA&#xad;AAAAAAAAAAAAAAAAAAAA&#xad;AAAAAAAA/&#x200b;BBBBBBBBBBB&#xad;BBBBBBBBBBBBBBBBB"
    expect(break_up_test("http://www.example.com/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBB"))
      .to eq "http://&#x200b;www.example.&#x200b;com/&#x200b;AAAAAAAAAAAAAAAAA&#xad;AAAAAAAAAAAAAAAAAAAA&#xad;AAAAAAAABBBBBBBBBBBB&#xad;BBBBBBBBBBBBBBBB"
    expect(break_up_test("www.example.com/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBB"))
      .to eq "www.&#x200b;example.com/&#x200b;AAAAAAAAAAAAAAAAAAAAAAAA&#xad;AAAAAAAAAAAAAAAAAAAA&#xad;ABBBBBBBBBBBBBBBBBBB&#xad;BBBBBBBBB"
    expect(break_up_test("aaaaaaaa-aa"))
      .to eq "aaaaaaaa-aa"
    expect(break_up_test("aaaaaaaa_aa"))
      .to eq "aaaaaaaa_&#x200b;aa"
    expect(break_up_test("aaaaaaaa.aa"))
      .to eq "aaaaaaaa.&#x200b;aa"
    expect(break_up_test("aaaaaaaa.0a"))
      .to eq "aaaaaaaa.0a"
    expect(break_up_test("aaaaaaaa<a>a"))
      .to eq "aaaaaaaa&#x200b;&#x3c;a&#x3e;a"
    expect(break_up_test("aaaaaaaa<<a>>a"))
      .to eq "aaaaaaaa&#x200b;&#x3c;&#x3c;a&#x3e;&#x3e;a"
    expect(break_up_test("aaaaaaaa/aa"))
      .to eq "aaaaaaaa/&#x200b;aa"
    expect(break_up_test("aaaaaaaa//aa"))
      .to eq "aaaaaaaa//&#x200b;aa"
    expect(break_up_test("aaaaaaaa+aa"))
      .to eq "aaaaaaaa+&#x200b;aa"
    expect(break_up_test("aaaaaaaa+0a"))
      .to eq "aaaaaaaa+&#x200b;0a"
    expect(break_up_test("aaaaaaaa{aa"))
      .to eq "aaaaaaaa&#x200b;{aa"
    expect(break_up_test("aaaaaaaa;{aa"))
      .to eq "aaaaaaaa;&#x200b;{aa"
    expect(break_up_test("aaaaaaaa(aa"))
      .to eq "aaaaaaaa&#x200b;(aa"
    expect(break_up_test("aaaaaaaa(0a"))
      .to eq "aaaaaaaa(0a"
    expect(break_up_test("aaaaaaa0(aa"))
      .to eq "aaaaaaa0(aa"
    expect(break_up_test("aaaaaaaAaaaa"))
      .to eq "aaaaaaa&#xad;Aaaaa"
    expect(break_up_test("aaaaaaaAAaaa"))
      .to eq "aaaaaaaAAaaa"
  end

  it "detects line status of document" do
    input = <<~DOC.lines
      = Title
      Document
      :attr1:
      :attr2:
      :attr3:

      == Hello

      A
      B

      ====
      C
      D
      ====

      [source]
      ====
      E
      F
      ====

      [pass]
      ____
      G
      H
      ____

      [pass]
      I
      J

      ....
      K
      L
      ....

      ----
      M
      N
      ----

      ++++
      O
      P
      ++++

      ////
      Q
      R
      ////

      S
      :attr4:
      :attr5:

      T

      :attr6: A
      :attr7:

      [comment]
      ****
      U
      V
      ****

    DOC
    pass_status = [
      true, true, true, true, true, false, # attrs: 5
      false, false, false, false, false, # clause: 10
      false, false, false, false, false, # example: 15
      false, true, true, true, false, false, # source delim: 21
      false, true, true, true, false, false, # pass delim: 27
      false, true, true, false, # pass para: 31
      true, true, true, false, false, # literal: 36
      true, true, true, false, false, # source: 41
      true, true, true, false, false, # pass: 46
      true, true, true, false, false, # comment: 51
      false, false, false, false, # no middoc attr: 55
      false, false, true, true, false, # middoc attr: 60
      false, true, true, true, false, false, # comment delim: 66
    ]
    p = Metanorma::Utils::LineStatus.new
    pass_status.each_with_index do |s, i|
      p.process(input[i])
      p.pass == s or warn "Error: line #{i}: #{input[i]}"
      expect(p.pass).to be s
    end
  end
end
