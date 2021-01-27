require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Utils do
  it "has a version number" do
    expect(Metanorma::Utils::VERSION).not_to be nil
  end

  it "normalises anchors" do
    expect(Metanorma::Utils.to_ncname("/:ab")).to eq "__ab"
  end

  it "sets metanorma IDs if not provided" do
    expect(Metanorma::Utils.anchor_or_uuid()).to match (/^_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    expect(Metanorma::Utils.anchor_or_uuid(Dummy.new(nil))).to match (/^_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    expect(Metanorma::Utils.anchor_or_uuid(Dummy.new(""))).to match (/^_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    expect(Metanorma::Utils.anchor_or_uuid(Dummy.new("A"))).to eq "A"
  end

  it "applies Asciidoctor substitutions" do
    expect(Metanorma::Utils.asciidoc_sub("A -- B")).to eq "A&#8201;&#8212;&#8201;B"
  end

  it "finds file path of docfile" do
    d = Dummy.new
    expect(Metanorma::Utils.localdir(d)).to eq "./"
    d.docfile = "spec/utils_spec.rb"
    expect(Metanorma::Utils.localdir(d)).to eq "spec/"
  end

  it "applies smart formatting" do
     expect(Metanorma::Utils.smartformat("A - B A -- B A--B '80s '80' <A>")).to eq "A&#8201;&#8212;&#8201;B A&#8201;&#8212;&#8201;B A&#8212;B ’80s ‘80’ &lt;A&gt;"
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
    <?xml version=\"1.0\"?>
<container><a>A&#x2013;B A&#x2013;B</a><b>A&#x2013;B</b></container>
    OUTPUT
  end

  it "sets hash values by dotted key path" do
    a = {}
    a = Metanorma::Utils.set_nested_value(a, ["X"], "x")
    a = Metanorma::Utils.set_nested_value(a, ["X1"], 9)
    a = Metanorma::Utils.set_nested_value(a, ["X2"], [3])
    a = Metanorma::Utils.set_nested_value(a, ["X3"], {"a" =>"b"})
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

  it "rewrites SVGs" do
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg", "action_schemaexpg1.svg"
   FileUtils.cp "spec/fixtures/action_schemaexpg1.svg", "action_schemaexpg2.svg"
   xmldoc = Nokogiri::XML(<<~INPUT)
   <standard-document type="semantic" version="1.8.2">
<bibdata type="standard">
<title language="en" format="text/plain">Document title</title>
<docidentifier/>
<docnumber/>
<version/>
<language>en</language>
<script>Latn</script>
<status>
<stage>published</stage>
</status>
<copyright>
<from>2021</from>
</copyright>
<ext>
<doctype>article</doctype>
</ext>
</bibdata>
<sections><svgmap id="_d5b5049a-dd53-4ea0-bc6f-e8773bd59052"><target href="mn://action_schema"><xref target="ref1">Computer</xref></target></svgmap>
<svgmap id="_4072bdcb-5895-4821-b636-5795b96787cb" src="action_schemaexpg1.svg"><target href="mn://action_schema"><xref target="ref1">Computer</xref></target><target href="http://www.example.com"><link target="http://www.example.com">Phone</link></target></svgmap>
<svgmap id="_60dadf08-48d4-4164-845c-b4e293e00abd" src="action_schemaexpg2.svg" alt="Workmap"><target href="href1.htm"><xref target="ref1">Computer</xref></target><target href="mn://basic_attribute_schema"><link target="http://www.example.com">Phone</link></target><target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap></sections>
</standard-document>
   INPUT
   Metanorma::Utils.svgmap_rewrite(xmldoc)
   expect(xmldoc.to_xml).to be_equivalent_to <<~OUTPUT
   <standard-document type="semantic" version="1.8.2">
       <bibdata type="standard">
       <title language="en" format="text/plain">Document title</title>
       <docidentifier/>
       <docnumber/>
       <version/>
       <language>en</language>
       <script>Latn</script>
       <status>
       <stage>published</stage>
       </status>
       <copyright>
       <from>2021</from>
       </copyright>
       <ext>
       <doctype>article</doctype>
       </ext>
       </bibdata>
       <sections><svgmap id="_d5b5049a-dd53-4ea0-bc6f-e8773bd59052"><target href="mn://action_schema"><xref target="ref1">Computer</xref></target></svgmap>
       <img id="_4072bdcb-5895-4821-b636-5795b96787cb" src="action_schemaexpg1.svg" mimetype="image/svg+xml" height="315" width="368"/>
       <svgmap id="_60dadf08-48d4-4164-845c-b4e293e00abd" src="action_schemaexpg2.svg" alt="Workmap"><target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap></sections>
       </standard-document>
   OUTPUT
   expect(xmlpp(File.read("action_schemaexpg1.svg", encoding: "utf-8").sub(%r{<image .*</image>}m, ""))).to be_equivalent_to <<~OUTPUT
<?xml version='1.0' encoding='UTF-8'?>
       <!-- Generator: Adobe Illustrator 25.0.1, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
       <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
         <style type='text/css'> .st0{fill:none;stroke:#000000;stroke-miterlimit:10;} </style>
         <a xlink:href='#ref1'>
           <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
         </a>
         <a xlink:href='mn://basic_attribute_schema'>
           <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
         </a>
         <a xlink:href='mn://support_resource_schema'>
           <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
         </a>
       </svg>
OUTPUT
expect(xmlpp(File.read("action_schemaexpg2.svg", encoding: "utf-8").sub(%r{<image .*</image>}m, ""))).to be_equivalent_to <<~OUTPUT
<?xml version='1.0' encoding='UTF-8'?>
       <!-- Generator: Adobe Illustrator 25.0.1, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
       <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
         <style type='text/css'> .st0{fill:none;stroke:#000000;stroke-miterlimit:10;} </style>
         <a xlink:href='mn://action_schema'>
           <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
         </a>
         <a xlink:href='http://www.example.com'>
           <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
         </a>
         <a xlink:href='mn://support_resource_schema'>
           <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
         </a>
       </svg>
OUTPUT
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
end
