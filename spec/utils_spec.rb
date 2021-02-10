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
<sections>
<svgmap id="_d5b5049a-dd53-4ea0-bc6f-e8773bd59052"><target href="mn://action_schema"><xref target="ref1">Computer</xref></target></svgmap>
<svgmap id="_4072bdcb-5895-4821-b636-5795b96787cb">
<figure><image  src="action_schemaexpg1.svg"/></figure>
<target href="mn://action_schema"><xref target="ref1">Computer</xref></target><target href="http://www.example.com"><link target="http://www.example.com">Phone</link></target>
</svgmap>
<svgmap id="_60dadf08-48d4-4164-845c-b4e293e00abd">
<figure><image  src="action_schemaexpg2.svg" alt="Workmap"/></figure>
<target href="href1.htm"><xref target="ref1">Computer</xref></target><target href="mn://basic_attribute_schema"><link target="http://www.example.com">Phone</link></target><target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap></sections>
</standard-document>
   INPUT
   Metanorma::Utils.svgmap_rewrite(xmldoc)
   expect(xmlpp(xmldoc.to_xml)).to be_equivalent_to xmlpp(<<~OUTPUT)
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
       <figure>
  <image src='action_schemaexpg1.svg'/>
</figure>
<svgmap id='_60dadf08-48d4-4164-845c-b4e293e00abd'>
  <figure>
    <image src='action_schemaexpg2.svg' alt='Workmap'/>
  </figure>
<target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap></sections>
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

   def datauri(uri, localdir = "")
        return uri if /^data:/.match(uri)
        path = File.join(localdir, uri)
        types = MIME::Types.type_for(path)
        type = types ? types.first.to_s : 'text/plain; charset="utf-8"'
        bin = File.open(path, 'rb', &:read)
        data = Base64.strict_encode64(bin)
        "data:#{type};base64,#{data}"
      end


  it "generates data uris" do
    expect(Metanorma::Utils.datauri("data:xyz")).to eq "data:xyz"
    expect(Metanorma::Utils.datauri("spec/fixtures/rice_image1.png")).to be_equivalent_to "data:image/png;base64,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"
    expect(Metanorma::Utils.datauri("rice_image1.png", "spec/fixtures")).to be_equivalent_to "data:image/png;base64,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"
  end
end
