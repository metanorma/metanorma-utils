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
    require "metanorma-standoc"
    expect(Metanorma::Utils.asciidoc_sub("A -- B")).to eq "A&#8201;&#8212;&#8201;B"
    expect(Metanorma::Utils.asciidoc_sub("*A* stem:[x]")).to eq "<strong>A</strong> <stem type=\"AsciiMath\">x</stem>"
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
<target href="href1.htm"><xref target="ref1">Computer</xref></target><target href="mn://basic_attribute_schema"><link target="http://www.example.com">Phone</link></target><target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap>
<svgmap id="_60dadf08-48d4-4164-845c-b4e293e00abd">
<figure>
<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
<a href="mn://action_schema" >
        <rect x="123.28" y="273.93" class="st0" width="88.05" height="41.84"/>
</a>
<a href="mn://basic_attribute_schema" >
        <rect x="324.69" y="450.52" class="st0" width="132.62" height="40.75"/>
</a>
<a xlink:href="mn://support_resource_schema" >
        <rect x="324.69" y="528.36" class="st0" width="148.16" height="40.75"/>
</a>
       </svg>
</figure>
<target href="mn://action_schema"><xref target="ref1">Computer</xref></target><target href="http://www.example.com"><link target="http://www.example.com">Phone</link></target>
</svgmap>
<svgmap id="_60dadf08-48d4-4164-845c-b4e293e00abd">
<figure>

    <image src='data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDI1LjAuMSwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPgo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IgoJIHZpZXdCb3g9IjAgMCA1OTUuMjggODQxLjg5IiBzdHlsZT0iZW5hYmxlLWJhY2tncm91bmQ6bmV3IDAgMCA1OTUuMjggODQxLjg5OyIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSI+CjxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+Cgkuc3Qwe2ZpbGw6bm9uZTtzdHJva2U6IzAwMDAwMDtzdHJva2UtbWl0ZXJsaW1pdDoxMDt9Cjwvc3R5bGU+CjxpbWFnZSBzdHlsZT0ib3ZlcmZsb3c6dmlzaWJsZTsiIHdpZHRoPSIzNjgiIGhlaWdodD0iMzE1IiB4bGluazpocmVmPSJkYXRhOmltYWdlL2dpZjtiYXNlNjQsUjBsR09EbGhjQUU3QWZmL0FBQUFBQUFBTXdBQVpnQUFtUUFBekFBQS93QXpBQUF6TXdBelpnQXptUUF6ekFBei93Qm1BQUJtTXdCbQpaZ0JtbVFCbXpBQm0vd0NaQUFDWk13Q1paZ0NabVFDWnpBQ1ovd0RNQUFETU13RE1aZ0RNbVFETXpBRE0vd0QvQUFEL013RC9aZ0QvCm1RRC96QUQvL3pNQUFETUFNek1BWmpNQW1UTUF6RE1BL3pNekFETXpNek16WmpNem1UTXp6RE16L3pObUFETm1Nek5tWmpObW1UTm0KekRObS96T1pBRE9aTXpPWlpqT1ptVE9aekRPWi96UE1BRFBNTXpQTVpqUE1tVFBNekRQTS96UC9BRFAvTXpQL1pqUC9tVFAvekRQLwovMllBQUdZQU0yWUFabVlBbVdZQXpHWUEvMll6QUdZek0yWXpabVl6bVdZenpHWXovMlptQUdabU0yWm1abVptbVdabXpHWm0vMmFaCkFHYVpNMmFaWm1hWm1XYVp6R2FaLzJiTUFHYk1NMmJNWm1iTW1XYk16R2JNLzJiL0FHYi9NMmIvWm1iL21XYi96R2IvLzVrQUFKa0EKTTVrQVpwa0FtWmtBekprQS81a3pBSmt6TTVrelpwa3ptWmt6ekprei81bG1BSmxtTTVsbVpwbG1tWmxtekpsbS81bVpBSm1aTTVtWgpacG1abVptWnpKbVovNW5NQUpuTU01bk1acG5NbVpuTXpKbk0vNW4vQUpuL001bi9acG4vbVpuL3pKbi8vOHdBQU13QU04d0Fac3dBCm1jd0F6TXdBLzh3ekFNd3pNOHd6WnN3em1jd3p6TXd6Lzh4bUFNeG1NOHhtWnN4bW1jeG16TXhtLzh5WkFNeVpNOHlaWnN5Wm1jeVoKek15Wi84ek1BTXpNTTh6TVpzek1tY3pNek16TS84ei9BTXovTTh6L1pzei9tY3ovek16Ly8vOEFBUDhBTS84QVp2OEFtZjhBelA4QQovLzh6QVA4ek0vOHpadjh6bWY4enpQOHovLzltQVA5bU0vOW1adjltbWY5bXpQOW0vLytaQVArWk0vK1paditabWYrWnpQK1ovLy9NCkFQL01NLy9NWnYvTW1mL016UC9NLy8vL0FQLy9NLy8vWnYvL21mLy96UC8vLy9qNCtQTHk4dXZyNitYbDVkL2YzOWpZMk5MUzBzek0Kek1YRnhiKy92N2k0dUxLeXNxeXNyS1dscForZm41bVptWktTa295TWpJV0ZoWDkvZjNsNWVYSnljbXhzYkdabVpsOWZYMWxaV1ZKUwpVa3hNVEVaR1JqOC9Qems1T1RNek15d3NMQ1ltSmg4Zkh4a1pHUk1URXd3TURBWUdCZ0FBQUN3QUFBQUFjQUU3QVFBSS9nQ3ZDUnhJCnNLREJnd2dUS2x6SXNLSERoeEFqU3B4SXNhTEZpeGd6YXR6SXNhUEhqeUJEaWh4SnNxVEpreWhUcWx6SnNxWExsekJqeXB4SnM2Yk4KbXpoejZ0ekpzNmZQbjBDRENoMUt0S2pSbzBpVEtsM0t0S25UcDFDalNwMUt0ZXJJZS8reWF0M0t0YXZYcjJERGloM3I5WjdWczJncAovcXU2TnEzYnR3cmJUcFVMdDI1ZHVsSHgydDE3VnU5VHYzd0Q1MlVydURCVndBcXRJU2tUVWpIampZZ05TejRhdWFDenh5S3R5Zm1ICk9XUGx5YUNEZmhhb3VYUGp4UnhIaDE2OVV5Nm5yQkFFT3N1YVFOYm1meENlbFVoMFRmRy9BTHgxSTBLQ08rRW8yck91emY2WFlKWmkKTXB1YlgzdEc0cDhPNVFtTzY5QXU4SFh4Z2FwWi9vdTMyZlpaaTFuUFRLQlg3N2c5RXVDbHIzRVNJSXU0Z0ZuT2dCKzBwaVE1cS9YTwpMYVlZY0xvbFlzMGNCaVl4bkhYVTZaQWVldWM5Q041NEZBSkYxMnozalhMZFFJNU50MXVCSGlZQ0lvZ0h2YmFoaGdSMTZCaDFXcFh4CjRJdnF5ZmJQZlJOV2FHTnJwQ0VCQVgrempCSWJoNmdWbUY5d0grNFdZa0tLWmZoampveXRHS05BTUFLbzJJNzkxWGpqbGVRSjVHTnYKL1kzb1JZY0ZUb2tkZWthU1dKQTFnZ2pVaVlobGZvbGFlM0pjZDFtVUQyN0pvNVZZNWhsVGVkVWh0eHlOcnowUUhYclYzYWZaakxZeApsOXlaeEgzMzV5eXZBZmZhZlN6dXVCbDBuQjJYVzUrS0NoU2VucUNHOUdsUm80WnFLbVNFbmFycVNhVkN4T0pXL3ZxbDFPcXF0RVkwCnEyaTE1Z3JTclJicTZtdHFaQVVyN0xERWl2WHJzUmp4K3BPeXlQN0tiRS9QTnB0cnREaEthKzFEMU9xVTdiV21ib3VUdDl6cUNXNlcKNFpaNzBMZzFvV3R1aGVyTzFPNjY0cjI3Sjd6MHlndVR2ZlJPaHE5TCsrWmJXTDhzQWV3dlh3S3JWUERBZDZXSzhMVUhvOVR3d21rOQpiSkxFRUZ0Rk1Va1hWenlYd2hvZm03RklIM2Y4RjhjaTY4cFBzU2luckxKWC9KVHM4a1QxdkN5enRqUFhUSzdOT04rYjg4Nzg4dXl6ClNqSC9MUFRRUkJkdDlORklsNXRQMGt3L0ZEUkJJVGR0clY1UlM5MHMxUWVaT1ZHSGlhRm0wb3BHV2gyeFFYb055QnRJbDZIOVdOb0cKbWMwUTIySW5oYlZCV25NVW4wZngzVTEzL3RoSXltRmEzRVU5amVlaHZ3VlgzWW5JS1llY2JvRDgwMFdSaDFSWEJ1RzVHZW1iZnNJUgp0NlJCM2xtYWxhQ3dNZTQ0NUllYlBTQWl0OFhHNG9hQUkwVVhKN0VOZVdDQ0JsYjUzNFBQYVg0NmNjMk5ZcWlBN3hub3QzejAyWWRmCnJBV1pKK1did09ObU5uWE5VZWRpbWJ1cGlLQTFTWnpkdWxGeVlVK2tpSnd5WnFLV3JCOVpJSWp1TVhZKzlXeCtueENHQVRZWkpQc2sKY3VJZysyQ0d2ejFsQTBrZm9vUXBRb0tTQ0RLaUl2SEdlMkRhelpEK3g3Nzk2SWhIS3ByZjkrcDN2KytCNlVuNzR4OXA1QkM5NnNWSgpPWk5MMHpYVzVLVUNnbzh4em1oT0FnMmtvekdaOENCMjZrOEUxVWUvTXJFSE5iSjcwd2ZobHNHZENNNVQvZ1NzemdGSVFLbnF4TVkzCmpzb0tmVGF6Uk9hc29rODBrczgvUUJlOVFqbUhpWW1TVHZJNDFaelh4Q1pRV0l4T29tYTBLTzhNOFQ1ZW5JNFJlK2lUdVlXa2JteVUKbGh0QkFzYzRJbXVPZURQZVJWNmxGZVRaOFY5aysyUFNmbmlOcWdtU1ZvWThwS3I4VXNlSGNBMUpYaXNKMkxSWGtrWXE4aU5sQzE1SQplTWdSdG5FeVIzNUV5Q2UzcHNtMy9lMlN0c29hM3pxaU43c05yNVVFWE9WK2hwY1JTM0tJbHFoc0NDSHBRampNSFU1TGlWdE9CeHYzCk9EWkZqak9VUXg5eE1GZUNCVzJ1SUowakhPaHdJN3BpNnVhWU9qRGRlMUFIR3pWYXh6aUpXNTM1ZnFrNDVvenhtYmxFeUJ4aHB4ejQKWEM5N2Q3cmREY21ndTIzeXJrZS8vcHRjOE9Jem4vcVFjWUYwaTlBTjVhZFA1d1VQZW9TYW5nWGY5RTVLY3NoMnptbG9tQ1E2MEVlbQpNeTZCSkUzMi9xZS84VjBEUmYycjRRR0JSOFAyTWRCOW9pVGpETTFud081VU1FVDVheEZDUE1wSGhkWVVwRXk2S0VQYzZML3pZVEJICkF3enBCQzBIVHdrdWNIMG9aUlNWNHRjYkNaN1VwU2E4NEtLNlJpa00rblNxV3dMU0tYVUt0WXoyaG9Oa0VwNmNRcWdta3o3REN5YjAKWHdxWkdxWVdydldGQm9raFUxZjRWTnpoRUQ0NkhPdCtSTGdtell3MVREdFU2SFRjdEZXdUNtU1hRZnpIR1FsVkhDVCs2RStKYW1JQwpucWpFTWs1eFVDd3lWQmc3dFVXdGRMRTRZRVNVR0c4VFJUTVNFVkxGcVJSQ0hBc2xJeDZxaUVray9xTVUwV25ZaExUTGxyWHQxa2h3Cm0xdFFxY3MzVWF3SUg3TVNTcE1NdDNDOU5WaHlhNGJZNWNvTWo4N3RHSFJyS2N1SVdOU0JoYVd1UTZQTEtxODZaSlFCTE81R3dNdksKVW5KWFZ0NWxDQ3hWdVYyTnJKZU8xVDB2U1pvckk2MWNaM1dVVysxdGZQbk5qd1p6Y1NVZ0p1bVFtVHBsSWpkejMrSGNQMEhiemN6aApsYi9saysrdU9MUlJPelgwdWdSaHArd3VERkc3MHRPZ0FWaFE3L0pwdXVIMTAzZ0FQUk10U3dFaEFDRVZwZzJWTU1nNGhLQ1BxaTU4CkdOYm9CRHZhWDV5eTFLVHBxMnRMRy9sVzdjSHZ4ZWZUbjR3bjNEOHJUZ2VET1ZaalNRRUlwS0JDU2FTOUtXcEpqenJrK0g2MURDeHUKNmxLUi9LR2ZMaG1USElyQy9sUy9PdFlvYTZhRFlnVWhtc3BhUXZxUkFJVXFsS0NZM3RyQWxENUdybTFGSVh3Q2UyYU0wSmR3V1ZIZgpHbWVMRUJZdFZyV3NMV2NUSlV0WjJVcVJpb3pWckdnNTJ6WTZMSXFQQ0hBQ0dVMExXOW9XT3BVRjZSNHIra2VEbVBEMjFCcnNLdmtHCk1vcnNudVRWc0NhVlZ4RWQ0YzdDcXIwWEFlNmFKM0pjOGVZYXZhaytkcjdvcTJ5RUpiTFpicUdXUlhHOU4yQkQyeW1qSWkrampMMFEKdDEzN01CQjViNk85ekJCcWY5c256RjVPVnU1YnV0U3g5NnZFYmUrazhNUGcxRFp6bjVvVTU3bVh0ZXNLSC9IQ2tRd3ZielFzM3J1eApXSGt2NnJLQllyeHZhTzI2eGx1cWFaVER0RkVpUjgvSVpDUXorR1RhY0o3TU1iUEpvZkxFL2o5MDV5UE5Fc3pKbVJLUE5FN2xqbnQ4CjEycE9VV0JITGp3NHY0OHpXanBpbDZwMzF6aHIyK1V4T2ZSdEV1M05INlZSeFlweTlHbFg2K25XYWlYVW84N0tveGNOOUY2Ulp0VlEKYW5YVmRTVVhuTlo2NjF5L3BYMFZVbXhnbHgzczBVYTdyNWl0OWxWTnQrMmhldnRRekExM2o4aGRsTFptaWJmcnZwSzd0dzJYTmFFNwozemVTN3EydzJ6cjUzWnN6dTlQTkZHcUhPOTdzTmVQdk01c3ZOdmplRHpaY2Z3ZVBNUXJ6eHNLMHk3R3doNFJ3RS9qVFFTUndFSHNZCnJ1TEhIRnlnWVkwcTZ6a3ZLaHAvL3NZdG9ybkpqNndlT2luWklFVWV5SkVWWGxQYWo0UXVJSC95VkhYZjFqSDMvdmtBNnJiZndxenkKblp1MXpNTTJQcE43L2hQelc3WTU0TEg4SHFDaGp6dEMrem5uWEFwcmgyUm5mdTBiZXRkRHg3bHFHWTEwU25NSzZwZ3FnNmFLbnBpbQplek1yVUlkR1VuZGE4K2QreWJKcldEY2RXbWVBb09GR1hwZDNEQWdYYnNSclpNY3A4YVlSWnhlQjg1SnNHbWdqYk5lQlYvSnNJRmd0ClRkVVpnb2RkSnppQzZRSkozR1laYTNOS2UvYytFS2lDQVVOMjVDWnpUUUo0NFNkOU0waURJMEZmNkxOZndCWk50ekZObFNOZ3hsUTYKK0JaaTdxWnZQdWd3R2VVMkJOZGVwVGRYemJNakIwVUNWU1JZZ2RZYnMvZUVuY2VCTUZWeDVBWS9LNVZXWVdNL1VSVWt2d2VHWVNocgpIRlZTRHJSVVo0aGw4dkZTWGRoeWJsZ1NQT1ZCTmhkWE9tZUZjb2hrQTlWT0xKU0QvbnExaC9NVmhaZ2xSRXZuYTRxU1JxRWxXV05VCldnTW9nTGhuYW9yNGhwc1lHaUxZaVMveEdSa0lpbEx4aWFSWUVoOTRpbWtuaHFvb2dic1djQ25JS0lKMWF6ZElpbklYZ3dyaFNUQm8KWGpLWUViaUlkM3Q0ZDYrV056b29WRHlJZ2JYNFpYc0loSllqaERNRkc5SlVZQUUyT2ttSWVFdklUYWxGVGpBVVRyODBJdVFrVE9kMAppbTBoaGJFalhsVTRRNzZCaFFTaWhRbTFoazN5aGFRQlViUGpQUk5GTzNhbFR6MElnbkpCY1VrRmZDckZQSVBZVW5mb2p2K0hjeVhTClh6V1ZaQzNpWTFIbWh2dEljbkxZTmc4a1F3RDVZeFJFa0hyb1FGVTFWVmRGYTV2VGtHRDRrRFVYVmpBVWlIVTRWTUZSaURtRWlDQzAKVjJYbFZ5QUUvbGgvMVNZZ3FZSE5kU2hWcEZpUG1GaklJWW1YdFdtMVFWcVdwWk9ZeUg4TzFFMUY5MXFNOVZpVlJYOVA2SGV0dURHcwpHSlZqTTVWWlk0SElwUktqU0pVUUFaVmMrUlNwK0pXcktKWjJZVWlUUkphMXh4SzY2RUF0S0J2NWlKWkF0QkxFdUZXNEpXNXdlVmhlCmhXQkcxM2paWVIyUTU0UUs1anhGS0kxSWVFMUsrR0RZaUh1U0o1WnpNM29FSWxDbjF5QzRBNC9UQVh2b1dFL3J1SVVFT1k4YmRaZUYKbEpkOXhuc3UxbnR0YUJuL1NGQVdtWVo0eUhPS3huRjMyWWNMNVh5akdYMlFSSWNWaVlabm80YjRFeVJtOXBxZ0tYNkJTQ2ZzMFg0RQpJVmNuV1ZjcWlWY3MrWE90ZUpPYk5WbjNKMnI1dDM4RkNJbWZaWG1nUTRsQy9zbDRSSWxhbWVpWnRnV2VZeW1lRnVNUlcwbWVMV0dLCjZBa3o2YldlU3VHVjdva3JWaWtUWjBtTDFzYUE4UGtSYXltUmJkbVNHUEdMQjhHY0xwZWZyUFJLeFhobDk2bU0ycVZlQjJvUldMRXkKRUJxaEVqcWhZbUVXVE1HTWl5ZEZ4ZUY0Zm9tUTJoaVludk9UMURTTjFsUUMyS1JOVE5oZ0gxb1F4OUVwNHVTTi9RV083b1lxVndOdQpUZlZQajdrZWtabDZrMGs3V1dPWkFKbU96OE9PMHJPWmxCbFBFV1dQMVVOUjhWT1RFcUdlM0dPalB5WWpHK2w3cnVtUCtWU0NxWm1iCnEzbUlCYmxWTkJVK0NwbG9EQWwrQjFpalV2bGoxVGViVWRJMXRvbWF1QWxWdTZrK3ZTbVJHeWxVVkpaVk9aVWFjaVNsSmpSK3N3bVQKbzJTYy9yZUpaZmRvaUNwQ25CekNWejZuVUlMS2hZVFZFVkNxYXhmS2lFQlphZitBZjV1aGY5bVlZTmJwblpmMm5KVTRsSXVWUnRVWgpRRWhaS1VvNWY0L2lsSjZCb09GbXByNjRHTEZJU20rNUVKUGFFQVE2TlUzVm4rUDFnbXlab1A0WmJKdktwMHl4cTMxcWNpUXhsK09XCm9IWnBYYkphRWJtNlUrMkpFZWRwWEZqcHErbDVaZGpFblQvU29qWW5UTm5ucmRFWU9pUTZZTmwwalUyNG9zWDVYNHJ5SElNU2VkangKZVAzVk9YRDRudGZ3b0YxaG9mN0NKNXBwbWJaVEh3UlNpQUcxUEFRbHBGbW9tWFBxaFQ3YU5oMVdVUWUxcEFteUlLaW5laTFHWmRPNgpFREZERGw5QkRzNEdxM2RJcGNsQlU3dmhZemVYcFhUMVlnTzVzTVYzL3BBblVqNHpsSkRrOXlUd2d5ZE1vYTlhd2EvOUNyTDJzNlpBCkZWWjZ1bG9US1loYktxY0xSYWZqeWloV3BxVk93cEV6R3lCTFpiTkx3YkZjNGJFZmF6N3FZWnlNaW1SZVVKTHBkNXlFeUZRcnlXYkQKbWlKYlM1TkJHbGpDMlNPQktMVkxnYk02dTdQd0psdDhWQnVONGpuTjBhcDB3MFdnT29sWk5LcmNXYXFkYW1xUjlpaVJrZ2p6cHFxWApzcW1hVXJlTGtyRU9RYlZaWWJWWGUwZE5JVGdQR3JkeWE3bkhTaEJVUzdud3NnM3hVQS95MEEzYmNxMlZsSzNDYW5kTmdSZFk0Uy9iCm9BL2xFQTdrOExwb3VoUjR3YkgrRWcvbE1CRGdBTGxXaDd0YnNRN1hvQThDc1E3RFN4RElxeFhFT3hETG14WE5lN3pKNjd6VEs3M00KL3F1ODFYc056L3NQMGF1OTJidTkzUXUrMkh1OTFFdSsxZ3U5eXNzUDJ3QTFGTnErN3Z1K0tOTVUzYnN3OVJBT0E4RU53TXR2SFJjTwo5ckMrMlVBUCtkdEdRQ2NPKy9BUC9GQU9BZXh3YUpmQUw3ZkF5Ym9VOHlzeURFeUMrUHBjRDF6QkJMRTBGVFBCTk5PNTg1a3ZISndUCklmeVpIMXd2RjV3VUVTeVNtK3N4TmdxZ0VpR2dEd0hEcm5QQ0l3T3lGdkdzMXRXZzJFYkRPOHl0NUdTdjViUnVmOWRObDJOdDRCcHkKN1lhVWFjckNhWXBRUldxWi9pYTBPU2crd1pVaThnaHd0MG9VSTN3VEk1ekN4aGl5aW1Nb0VFZTRUdFZJWVpwNzBkckRuSXU3ditsUwpQcHQ4MkdXSXltcW50S21sSk9Nckl3eWJ5bWVjM1FkSjhoTTcvbHAwSm96NnFFNkt3VXpNeG1KSU9EUlN0Mk5FZEFlSmUxV01xdDh4CmYwZTN4TTdTdXRXS0pBbjREQXVJU0R4c0ZGNzhFQTlvTXZCYnlxWjh5bG5STXBZc2ZmYUZ1azczYS9GNWZMRzh5clBzd2JXTUZLRnMKeHpic0VCSDBEdzZReHJkOHB2ZTZiYXRidHJOVHE4R01xNW04eTMxamdzbVl6QmVoeDcya2VmZDFiNEpwcnNjMG90VHNJWTJUeGREYwptSm8waFp5NUlKU25uTS9EYys0MHNab0R6UldSeS96SVVTMkNrY1FucHMvTXpnNGhrajJGZmNhWWg4Um5WZlZzejlTS29HK21mbXJMCnNncjNxTWdNMEhHSms0dzFkZGNzV2FnRk9rT1VGWmlTazU0VHlRcjlwQmtkRkxtODBRbzh6Qjdkd1NBZDB0K3l6Q1JORThoNi90SXEKNGM3VlpVc0pyZEwzREVvTzVjSzlXc3d3SGMxZnZJTUo4ZEkzcmN5d2FxK0c2YUhmeE5NOUhaNElXb1ZPZkdlY2FWSkZyUkVzZlRiRAp4NlVKK2M5TjdkTncySHdycDVwVVJ0UkZEWnVBWmtOWE5KTTJYZFVZeFlHdmhhbEIyWlJKeVVSSlM5YllZdEp1blJJZEhkY3JTTmRjCmJOZDNqZGQxcmRjc01kZDhEWVdzS0tBeS9OZnFCSDk1aDhPZ2dyT292TmlNamNxYVc5Sm12YTZJZHlsSW9BTXpPaTBRbzU0VHlGQ2gKcHlCcFVzaDVzc1dVeWhPNUhGTkVwMHplUEI2aXJjV2pMVlVFcEFMWEFkcFlzdHBEQWJ6ZGsxY3hTUVB6Q014eGw5bWp6V2lLdXlsRgpHWFo1SXR1Nit0dVZheEtEalJPSGt0cm40aE4rdmNMTC9xckRRR0hjQWQzQUl3M0N0RVliQXN0Q0JHS2lrdU1oeC9RWVJjek5XMEZiCm91TWk1SFRFTjVwNTU5ek40aXF2Q01IZTRncXZMdnBMSExvZDlhckVKUHh5aXAyelY0dWtCU1JpK09SUEkzWkZWT3hQUnlTcjZjaXcKQ0NTUEprWXAxTE40OTdqVSsvR3dUUnF4QzZmT0RNS2p2UWQ3Ym52WGtsdTFsVXV5S0ZtQ3FCMm56TWRqR3hLbkwrWmpMYXRnTHh0QQpCQ1d6c3lteUlVNHUvLzNZNjhKTEFrU1NMMGFQUkpVSVhBWmswVG9pWnBZa3gzUGlMNzQ1R1VuSFFSdXpWdlcwUGh1WHBDMFFJejY1CkN6T09nOXh6YXJXRlk3Sm5OcWQ3aE56bGdDeTIzKzArWi9Xb0xqbENaaFdwY1BKWFR5dFhPWjRUY092Yk4vb2RwRlpwL29zTVJaOW0KUlVycHFodEV0MnNVYVhCc1dnR2dBckxWcXFjS0pFaHB1SVdUdUs2MXVKbENUWHhyNVQ4eDRxQXIzVFpJU1Z4ZGxrT1J1UnY4RUZyego2UWtqRko4THU2TmJ1cW9oYkRsaWFhU3V1aXpoeWpQV0UvTnJ1L1FTdTdOYnU3UXRGSnBkRUxxYkw3enJ1NzB1bnp4UkQ4bHJ2TjVyCnZzdU92dVhyN09mTHZlTUw3YzB1N2M5dTdkRWV2dCs3N2N3dXZ0ZXU3ZDJ1dnV6YjJPUmU3dTk3WnZWN3Y4VWV2QkxHdi80THdIaSsKWkFSc3dBZ2M3N0MyN3ZxYmEvZ3V3TWUyN3g5OTcvWithdjZPM1FDLzVjbzI4QlFzOEFGZmFBZ3YwZ1dmM0FwdjhQMis4R2ZXOENKOAo4QlMvWkJZUDJmcWU4VEsyOFhtZGF5ZGo3aVJmRnZJcG84cUVuZklxdi9JczMvSXUvL0l3SC9PaEVSQUFPdz09IiB0cmFuc2Zvcm09Im1hdHJpeCgxIDAgMCAxIDExNCAyNjMuODg5OCkiPgo8L2ltYWdlPgo8YSB4bGluazpocmVmPSJtbjovL2FjdGlvbl9zY2hlbWEiID4KCTxyZWN0IHg9IjEyMy4yOCIgeT0iMjczLjkzIiBjbGFzcz0ic3QwIiB3aWR0aD0iODguMDUiIGhlaWdodD0iNDEuODQiLz4KPC9hPgo8YSB4bGluazpocmVmPSJtbjovL2Jhc2ljX2F0dHJpYnV0ZV9zY2hlbWEiID4KCTxyZWN0IHg9IjMyNC42OSIgeT0iNDUwLjUyIiBjbGFzcz0ic3QwIiB3aWR0aD0iMTMyLjYyIiBoZWlnaHQ9IjQwLjc1Ii8+CjwvYT4KPGEgeGxpbms6aHJlZj0ibW46Ly9zdXBwb3J0X3Jlc291cmNlX3NjaGVtYSIgPgoJPHJlY3QgeD0iMzI0LjY5IiB5PSI1MjguMzYiIGNsYXNzPSJzdDAiIHdpZHRoPSIxNDguMTYiIGhlaWdodD0iNDAuNzUiLz4KPC9hPgo8L3N2Zz4K' id='__ISO_17301-1_2016' mimetype='image/svg+xml' height='auto' width='auto' alt='Workmap1'/>
    </figure>
<target href="href1.htm"><xref target="ref1">Computer</xref></target><target href="mn://basic_attribute_schema"><link target="http://www.example.com">Phone</link></target><target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap>
</sections>
</standard-document>
   INPUT
   Metanorma::Utils.svgmap_rewrite(xmldoc)
   xmldoc1 = xmldoc.dup
   xmldoc&.at("//image[@alt = 'Workmap1']")&.remove
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
<target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap>
<figure>
             <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
               <a href='#ref1'>
                 <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
               </a>
               <a href='mn://basic_attribute_schema'>
                 <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
               </a>
               <a xlink:href='mn://support_resource_schema'>
                 <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
               </a>
             </svg>
           </figure>
<svgmap id='_60dadf08-48d4-4164-845c-b4e293e00abd'>
             <figure>
             </figure>
             <target href='mn://support_resource_schema'>
               <eref type='express' bibitemid='express_action_schema' citeas=''>
                 <localityStack>
                   <locality type='anchor'>
                     <referenceFrom>action_schema.basic</referenceFrom>
                   </locality>
                 </localityStack>
                 Coffee
               </eref>
             </target>
           </svgmap>
</sections>
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
expect(xmlpp(File.read(Metanorma::Utils.save_dataimage(xmldoc1.at("//image[@alt = 'Workmap1']/@src"))))).to be_equivalent_to <<~OUTPUT
       <?xml version='1.0' encoding='UTF-8'?>
       <!-- Generator: Adobe Illustrator 25.0.1, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
       <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
         <style type='text/css'> .st0{fill:none;stroke:#000000;stroke-miterlimit:10;} </style>
         <image style='overflow:visible;' width='368' height='315' xlink:href='data:image/gif;base64,R0lGODlhcAE7Aff/AAAAAAAAMwAAZgAAmQAAzAAA/wAzAAAzMwAzZgAzmQAzzAAz/wBmAABmMwBm ZgBmmQBmzABm/wCZAACZMwCZZgCZmQCZzACZ/wDMAADMMwDMZgDMmQDMzADM/wD/AAD/MwD/ZgD/ mQD/zAD//zMAADMAMzMAZjMAmTMAzDMA/zMzADMzMzMzZjMzmTMzzDMz/zNmADNmMzNmZjNmmTNm zDNm/zOZADOZMzOZZjOZmTOZzDOZ/zPMADPMMzPMZjPMmTPMzDPM/zP/ADP/MzP/ZjP/mTP/zDP/ /2YAAGYAM2YAZmYAmWYAzGYA/2YzAGYzM2YzZmYzmWYzzGYz/2ZmAGZmM2ZmZmZmmWZmzGZm/2aZ AGaZM2aZZmaZmWaZzGaZ/2bMAGbMM2bMZmbMmWbMzGbM/2b/AGb/M2b/Zmb/mWb/zGb//5kAAJkA M5kAZpkAmZkAzJkA/5kzAJkzM5kzZpkzmZkzzJkz/5lmAJlmM5lmZplmmZlmzJlm/5mZAJmZM5mZ ZpmZmZmZzJmZ/5nMAJnMM5nMZpnMmZnMzJnM/5n/AJn/M5n/Zpn/mZn/zJn//8wAAMwAM8wAZswA mcwAzMwA/8wzAMwzM8wzZswzmcwzzMwz/8xmAMxmM8xmZsxmmcxmzMxm/8yZAMyZM8yZZsyZmcyZ zMyZ/8zMAMzMM8zMZszMmczMzMzM/8z/AMz/M8z/Zsz/mcz/zMz///8AAP8AM/8AZv8Amf8AzP8A //8zAP8zM/8zZv8zmf8zzP8z//9mAP9mM/9mZv9mmf9mzP9m//+ZAP+ZM/+ZZv+Zmf+ZzP+Z///M AP/MM//MZv/Mmf/MzP/M////AP//M///Zv//mf//zP////j4+PLy8uvr6+Xl5d/f39jY2NLS0szM zMXFxb+/v7i4uLKysqysrKWlpZ+fn5mZmZKSkoyMjIWFhX9/f3l5eXJycmxsbGZmZl9fX1lZWVJS UkxMTEZGRj8/Pzk5OTMzMywsLCYmJh8fHxkZGRMTEwwMDAYGBgAAACwAAAAAcAE7AQAI/gCvCRxI sKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkyhTqlzJsqXLlzBjypxJs6bN mzhz6tzJs6fPn0CDCh1KtKjRo0iTKl3KtKnTp1CjSp1KterIe/+yat3KtavXr2DDih3r9Z7Vs2gp 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' transform='matrix(1 0 0 1 114 263.8898)'> </image>
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

  it "rewrites SVGs with namespaces" do
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg", "action_schemaexpg1.svg"
   FileUtils.cp "spec/fixtures/action_schemaexpg1.svg", "action_schemaexpg2.svg"
   xmldoc = Nokogiri::XML(<<~INPUT)
   <standard-document type="semantic" version="1.8.2" xmlns="http://www.example.com">
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
   <standard-document type="semantic" version="1.8.2" xmlns="http://www.example.com">
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
    expect(Metanorma::Utils.datauri2mime("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAADfCAIAAADDbnkhAAAAKXRFWHRjb3B5bGVmdABHZW5lcmF0ZWQgYnkgaHR0cDovL3BsYW50dW1sLmNvbREwORwAAAEOaVRYdHBsYW50dW1sAAEAAAB4nHWQy27CMBBF95byD7OEhRFJoaJRVREKrZQmKiKEvUnc1FIypn5E6t93AkJdtCy8mTk+99pL64RxvmsDlrSqksCfYKWPMSTefUp0qhJOaYSd/PLSuoDREjhBZ/ofzJ40WhmwPz7URBoQN7wX+pHzCy5u4Vf/UmJ9rs22rUBX5hn00tgBCifRNJpOwvmo8AgpnWgBURjfPcSzOSSbYg8DMGaj120GVntDybWyzqijH2LGLBW9gJ2n4I4e+X6SmK7frgPYYK+Mxo6KsfSQ/wL3M75SDgppqAsccraWH8K3jm5UulbYxFDuX/iCZQIbLxpyy5Y9a/Kab/qjkv0A6yGCEpbMNRwAAB/mSURBVHhe7Z0JdBRF/seTEK4AIaKIgKCAsIBcBhUSQCCE4wEusuxyCMohIrjyniJyGK7/Iuiu4XQBAXch4RHDEBKJslxmAYGA4YjyWA8QIi4EISIElBdQMv+vU9LbdlV30jWT6snM7/Pq+TrV1b/+1fD9TnVN4vxC3ARBOEqIsYMgCLWITXjz8tULu474Vbt55ZoxS4IQ4ax6JYQqNiFipYY86lft4u4jxiwJQoSz6pUQqpUJv1iUeGFXquPti4WJcnMjghOn1CstVCsTIm5x8VHH27f/TpWbGxGcOKVeaaGWGxNuW7g6Ozs7Nzf3xIkT586dKywsNCZNEB6cUq+0UMuNCV1zFmRmZmZlZeXk5GB6BQUFxqQJwoNT6pUWarkx4brp81NSUjIyMjA9vM3gPcaYNEF4cEq90kItNyZMnjZv7dq1mB7eZrDc5+XlGZMmCA9OqVdaqOXGhBtmJ2JuSUlJLpcL7zFY6I1JE4QHp9QrLVQyIRFoOKVeaaH62IRLlkx5882X+H5vmvTciOBEWr1mrZSqlhaqpAlPnsysUCHsoYeaG/p79Hg0JqYNO+7VK6Zz53b8tXab9NyI4MRavZ06tQvzUKNGtSee6L5v3xp+jKHpVW3RpIUqacJZs8aFePj0U5e+X5/uzJnPTpkykr/WbpOeGxGcWKsX+mzY8J6FCyf369cFAq5T585bt47ww/TNH02IpBs1ql+tWlXM4ZVXfmOzEtPlJ4wevlPfpOdGBCfW6oU+27X7nXYMDZ85s1U/gFejXtX8Wa1JC1XGhLt2rUbqb789o1atmvXq1f7558PaKX26Y8cOHD68LzsuKvo4IeGZxo3r4yG2fv27V66cgc7r1w+OH/9HBImKqvHii0/+9NP/4uib9NyI4MRavXoT9u/fBYL88ccDxR6JYkVp0KBOpUoVo6Obb9++XLuEqXrVqplNmzbE2jN0aO/Cwr18ZGmhyphwzJgB1atHXLu2//nnB8ONfLr8MQyJkU891W/z5sVLl07dtm0ZiwMHLlo0GQ+ueEZfvvxV/l7FXsyNCE6s1QtNtm3b7Kuv3ofwoLqpU0ex/mef/UN4eIWRIx9fvXoWXBoaGnrwYDI7BSVHRFTB4jF9+pi4uEeg5Nmzn+MjSwvVtgl/+CEbO1rkimNkyaylnRWaMD9/J2bbrNl9+jisc9KkEezHNm2adu3aXj9Aa9JzI4ITC/UW334EZfTuHYMFEJ3nz/+ixkGDerAx3323CyYcOLA7+xFKrlv3Lu2pFetkx46t+cjSQrVtwnXrXkP2K1YkfP55OhqSwwKNVVFLlzdhVtZKXPLSS8P1cVgnLof90LC0Yp/J367Yi7kRwYmFeos9JnzwwSb79q3BGhgZWa1bt4evXt3HdlhYG7VhGKMtG4ZPOrCHwkPs5csfGSJLC9W2CXv27Ki9kWgkJc3l09WOd+58G2NmzBirj8M6hw3rg/0ha7A3f7tiL+ZGBCcW6i3+7Z6QrSjr18/H/ggH2PVpwx5+uOX999djxwYTTpjwJwz+/vs9hsjSQrVnwm++2YpVe8qUkV9//S/Wjh59F+8KcCafrnZ89ux2LO54ENeHOnduBzr79etiuAXfpOdGBCdm6mVNb8I9e/4BO2FJPH36AxyMGvV71o8nO+wPhapGa9++xV13RfGRpYVqz4Tz50+ECeE9fSeMhE44rdjEhGjDh/fFJIcM6bV79zspKa9nZCxEJzaWMPC0aaOPHXPt34/M/2K4HWvScyOCEzP1sgZNNmly79aty6C3li0bYyU4dGg9+vv27RwVVWPp0qn4EUKFXNPTF7BLoOSKFcPnzXvh1Kn358wZD38mJDzDR5YWqj0Ttmr1QK9eMYbOtLREZJyYOAnH8fEdYmPbsn798ZUrewcP7gmvYmRERJW5c/+MTjyLjxkzAFNCJyapvfEYmvTciODETL2sQZNsD4UN4YAB3ZKTf90EnT+/s0+fWHgSp6pXj1iw4GXtEpgwOro5HlBxCgOGDu3NfqthaNJCtWdCLxtW+by8LfrfKxZ7fj9z8mQm+5BK2KTnRgQn3qi3sHAvL1EsIVgwij0bK/7zGK1JC1WpCeWa9NyI4MQp9UoLlUxIBBpOqVdaqGRCItBwSr3SQiUTEoGGU+qVFiqZkAg0nFKvtFDJhESg4ZR6pYVKJiQCDafUKy1UKxN+sTARcR1v7Cv+JeZGBCdOqVdaqFYm9KsmMTciOHFWvRJCFZvw5pVrF3cfYW3bwtWuOQvWTZ+fPG0ebuBYW5Nsd25EcOKweu0LVWxCPdnZ2ZmZmSkpKWv9AFtfbEwQTqnXllBLNmFubi4MnZGRgbhJjmL3K/4JwhH12hVqySbEepqTk4OIcLbLUewWuyEIR9RrV6glmxBWRix4GmtrlhRrx79q7JLCbtk3gpBWrzeitSvUkk2IKHAzwuHp9oQUSypGG7ukQAJIA8kgpaKiImOiBMEhrV5vRGtXqCWb0HtSQx41dhGEf6NStGRCghCgUrRkQoIQoFK0Kkx4fM5qYxdB+DcqRavChARBWEAmJAiHIRMShMOQCQnCYVSYUOUelyB8gkrRqjChyk97CcInqBQtmZAgBKgULZmQIASoFC2ZkCAEqBStChOq3OMShE9QKVoVJixTTp48mZ+fb+wliPKDX5gwNzd38uTJn3zyifFEKWjVqtULL7xg7PWOBQsWvPfee8Zem/gkCHjjjTcme/jrX//6n//8x3iaKP/4hQmHDBkSEhIyYsQI4wkRH3vQfvSJCQ0xO3XqNGXKFN35UuGTIDxNmjRp3Lhxnz59IiMj8SolJSUZRyjBMDvChzhvwoKCgkoeqlatevnyZeNpjpiYmJEjR2o/WpuwuLjY2CXCEFMOnwThgQnHjh2Lg6Kionvuuadbt276s6WcoDWlCVJGsyPcakxovcdNTEysXLnymjVr8Db/97//Xevv3LnzW2+9xY4XL17ctWtXHLzyyisYXKNGjWbNmq1bt87tMeGECRNefvnlOnXqtG3b9sMPP2SXfP3117169apSpcr999+fkZHBOh9//PE5c+YYBvMxMWzu3LnskrNnzw4ePLh27doYgwHs2wpwtkOHDuhp06bNzp07Swzy3//+d+DAgXd4GDRokPYNXMJ8DGgmBI96YMfCCZ45cyY+Ph5vZy1atMBVSIYZTPhimgX54IMPunTpgrfF+vXrf/nll27R7AIea9H6FhUmtP60t3nz5sOHD//555/vvffedu3aaf1169adPXs2O54xY0aDBg1wcPr06datW/ft2zcnJ+fChQtujwnDw8N79+69adMmCDQ2Nhadt27dgqYhx8OHD0+cOBELCIsjHCyMyVbXn376CSnVqlULG7zPPvts8+bNyBP9r7/+elpaGnZoEHf37t2tg+CShx56CK7AFhFCx0H79u2RoVk+BpgJv/rqK+SA96lly5a5TSYIv+FGiLljx46srCy8QWA8M6HwxRQGQbZ4x3nuuefy8vLwpnDlyhW3aHYBj7VofYvDJtyzZw+Egv/iGCrBMQTBTgl14+aei6A5vG3fvHkTx/Pnz8cigIMDBw4gFKyyf/9+l8uFY/apj3CwMCbzD4szefJk7ZSeH374Yfr06Vgf2I9mQQ4ePIggK1euZP0rVqzAj4cOHWJjhPnogQlDbvPaa68xUwkniJcOB++88w67EHcMsTShMAjG16tXD28T8Bsbzwi2x1EL0foch004YsQI/NsPGzbsySefjIuLw/H48ePZKaFu3Jwa9HvCRYsWMR2npqYiVOPGjR+8DRYus8Fu85gsDh7PtFOM5cuXIx88Q+IWJZqQBTly5Ajrh/3w48aNG/Vj3L/NRw9MiOfho0eP4lG2X79+rFM4QWYkjGRjSjShMIjbY048duJU//79L168yK4iE5YdTprw+++/x24E9vvbbfBIVrNmzR9//NHt0c2rr77KRuJ5VW/Cp556Sgsi1DF7j1+92vhYLxzsNo+ZnZ2NOAkJCdopsHv37pDbC86bb76pN6EwyEcffYTxycnJrP+f//wnfkRk/Ri3pQnZnnD9+vW4EMPcJhM8duwYOvFky37EBltvQv7FFAZh4CpYulq1atOmTWM9htkFPGaiLQtUmNBsj7tkyRLIDlbUerDmQBZr167F8WOPPYY9Eh6QJk2ahE7NhFg8mzZtqn2OKtQx28vh7Xz79u1FRUUIcubMGbPBbvOYiIOdFTZLsNC3336bmZmJNwjs65APNnhwF/aEFSpUuHr1qkUQJIDVBiOxh0QmHTt2fOCBB9gHPGb56NF/MIMlsVKlSlhUzSbYsGFD3AiPl3gNYSHNhMIXUxjk+vXrsOU333xTUFBQv3597cHEMLuAx0y0ZYEKE5oBfY8aNUrfc+vWLeiDfXa3efPmu+++OzQ0ND4+fuLEiZoJsYbcd9994eHhbC1q3bo1zrJTixcvjoiIYMd5eXmIA8EhAh7kEM1isEXMkydPPvLIIyEesFmCFaHdHj164MfIyMh58+YhSPPmza2DQN942GNB2rZt++mnn7J+s3z06E146dIlrGnwMKwinGBKSgqcjE5cha2sZkKzF5MPcuXKlUaNGuHHypUr9+zZ8/z582ykYXbllOv5BadWZdy4VPK3YqvESROWyM2bNyE7Y6/nYQlv1eyDSmsKCwtL+Udt1jGxLBgyuXDhAtyIAyyD2ledWwfB/uq7774z9noHP8EbN26wX4Ho94Ru8xfTLQqCFY///nbr2ZUXLu4+kl6r54ERswv2yvyFVlng1yYkvMFgQkLj/LZsV8XYDWEdtjQf/OWidx1fGMmEAcvhw4dnzZpl7CU8MB+6KsV+0HRQWo1uzi6MKkyoco9LEKWE+TDVU+M6s8Hj79Xtq18YVYpWhQnZPKlR8/OGhRH/TYuMy9+anRpgv6JQOR+CKCW/fEJzR4+0Kp1/NWFYh0139Mh9eQlbCVWKlkxIBCPMgWzp21AhZkeHMd/u/Fg/QKVoyYRE0AEHbqzSBbLUL30GVIpWhQlV7nEJwhrP7wnjP+z0rGHpM6BStCpMSBB+Av3FDEEQAsiEBOEwZEKCcBgVJlS5xyUIn6BStCpMqPLTXoLwCSpFSyYkCAEqRUsmJAgBKkVLJiQIASpFq8KEKve4BqhcDCGHStGqMKGXULkYC6hcTABQDkxI5WIs8JNyMYQ3+LsJqVyMNQrKxXiPn6Tht/i7CalcDJ+8HlvlYvhKL27PXWbOnDl69OioqKgGDRrgpWb9drMSBhemQRhQYUJv9rhULsZX5WKElV7cnruEhYWNGzfO5XJhIYWLrl27ZjcrYXBhGuUFb0RrFxUmlP60l8rFCPPRU/pyMWaVXnAX7fvtjx8/jsHp6el2sxIGF6ahnfVzpEUrgV+bkMrFCPPRU/pyMW6TSi/6u2Btx6qYkJAgkRUf3CyNcoG0aCXwXxNSuRizfPSUvlwMg6/0or8LKymDdU8uK0NwizT8HznRyuG/JqRyMWb56Cl9uRizSi+4C7Z8WEvR//TTT+Mu+fn5drMSBhemwS70f+REK4cKE8rtcalcjFk+ekpfLsas0gtMFR0dXbt2bZzCg4ZWWc1WVmbB+TRYv/8jJ1o5VJiwRG5cKjy1KuN6foHxhCVmFU5KX7eEL4RihnXMclQuhq/0wlY2vMEJc7OVFR+cwadB6HHYhGcz9ux4dPSmWvEXd//6GQChGP3jJeEIzpiwqODyoXHz02p0w5P3xqpdyIEOsmzZsi1bthh7CYWoNiGWvm1tR6SGdYT90iIey6A1kAh6VJgQe9z/LX2hvxbfSK8ZRw4k/JZA+2Dml0WvZhz+uymyO3Mg2oawjsf/7x1MFcdswnRMx35yzH50q0KRCW9cKvxy0bv/ajkks8HjW1sO2eB5HHWFx5zL/Mg4miD8gAA0oXZcsPeTAyNmp0XGbW39JBZG8iHhnwSyCRnawrghrIOrYuy59/caBhCEs/CiLTtUmJA9agthC2P6nT3pExrCr7AQrc9RYcISkfuLGYIIDPzChAQRzJAJCcJhyIQE4TAqTKhyj0sQPkGlaFWYUOWnvQThE1SKlkxIEAJUipZMSBACVIqWTEgQAlSKVoUJVe5xNfyhHpM/5EDIoVK0KkxYIt7UXTLDH761oSxy8Ek5J58EcVNNKB/hFya0VXfJjLKox2SXssjBJ+WcfBKEx09qQhlmV+5w3oR26y6ZYfYV10LKqE5QWeTgk3JOPgnCo6AmVGmClNHslOG8Cc3qLplV/xFWC+LLHrWyWY8pISFh2LBh1apVO336NOtk8CWW3FQT6ja2akKdOXMmPj4eb7UtWrTAVUiGGUz4YpoF4Ws/8bMrd6gwofUe16zuUiuT6j/CakHCskf85WZ1gjA4NDT06aefxr/x9evXtRzcohJLbpNKGN7nwA8WxmSra/mqCQW/4UaIuWPHjqysLLxBYDwzofDFFAYR1n7iZ+cTrEXrW1SY0OLTXou6S61E1X8sqgXxj4L85WZ1gjAYGxvtWh5DiSWhbtxe58APFsZk/ilfNaHwzxpyu0QHwB1DLE0oDCKs/eTmZucTLETrcxw2oUXdJU0obq6gkrBakJnO3NzlfJ0g/WADwhJLQt24fZdD4NWEYkbCSDamRBMKg7hFtZ/c3Ox8goVofY6TJrSuuyQUgUW1oBiTskdum/WY9JiVWKKaUIzS14Ri9Z60QhfY/IfoTMi/mMIgDEPtJzc3O59gJtqywEkTWtddEorAolqQWdkj/eVmdYLMTGhWYolqQjFKXxMKAxo2bIgb4fES/76wkGZC4YspDCKs/eTmZucTzERbFqgwodke17rukrD6j9u8WpBF2SNb9Zj0mJVYoppQjNLXhMKAlJQUOBmduApb2ZDbJjR7MfkgZrWfDLOz4Hp+walVGTcuCarWGDATbVmgwoRlgbBakHXZIz226gQJSyxRTagS4Sd448YN9isQ/Z7Qbf5iukVBhLWfrGen5+LuI+m14j/qP6lgry//QssbyqsJiXKNwYSKgQ9dlTqlhj66uV7fz/+2rjQLY5lCJiQc4PDhw7NmzTL2KgQ+3OSpjLKhYidX5c57+jm5MJIJiSBF82GqpzjKxqpdnFoYVZiQTZIatXLR0iLj8rdmB9oHM6kKP+0liFKClTCtahdmPGwRN0XFvd/oiS8XvctWQpWiJRMSwYjmwE139NhY9bH9QxIMe0KVoiUTEkHHL5+OVoxNDe2gX/oMqBQtmZAILtjvCfmlz4BK0aowoco9LkFYQH8xQxCEADIhQTgMmZAgHIZMSBAOo8KEKve4BOETVIpWhQlVftpLED5BpWjJhAQhQKVoyYQEIUClaIPOhP5QpMUfciCsUSlaFSZUucctEbPvdFJJWeTgkxovPgniDohCMSpFq8KEzlIWRVrsUhY5+KTGi0+C8PhJoZjyQuCb0Ox7b4WU0beelEUOPvnGW58E4VFQKMZ7/CQNt5+bkK9t4jYvVCIsbMJXC2lls0gLFYop60IxfI0Xt+cuM2fOHD16dFRUVIMGDdasWcP67WYlDC5Mw0H82oR8bRO3R8F8oRKzwiZ8tRDh5cLyI2wwFYop00Ixwhovbs9dwsLCxo0b53K5sJDCRdeuXbOblTC4MA1nUWFCL/e4htomrUSFSiwKm/CPgvzlwvIjbDAVinGXZaGYYpMaL7iL9s32x48fx+D09HS7WQmDC9PQzmp4KVpbqDCh9Ke9wtommlDcXJUVYWETM525ucv58iP6wQaEuZXehHI5BF6hGLdJjRf9XbC2Y1XEvkAiKz64WRoGpEUrgf+a0Ky2ifDltihsYlYLxW2zSIses9yEtU3cvsvBYEJhzPJVKIZRzNV40d+FFZPBuieXlSG4RRp65EQrh/+a0Ky2ifDltihsYlYLRX+5sPyIYbAes9yEtU3cvstBLy+zmOWrUIxZjRfcBVs+rKXox54cd8nPz7eblTC4MA12oR450crhFya8canw1KqM6/kF+k6z2iZmhUrMCptY1EKxVaRFj1luZrVNfJVD4BWKMavxAlNFR0fXrl0bp2rWrKnVVLOVlVlwPg3Wr6dE0foQFSa02OMW7P3kwIjZ6bXiL+7+9UHfgLC2iQXCwialrxbClx+xQJibWW2TssjBOmY5KhTD13hhK9utW7eEudnKig/O4NPQYyFan6PChDxY+r5c9O6WZn/cENbBVTH2250fG0cQwY3ZRiAgUW1CtvRtrN4ts+HvN1TouLFyJ3IgwbNs2bItW7YYewMURSbUlr6Mu/tk3Nkz1fPd4+RAgnCrMWH+1uy0yDi4Dksfsx87/uyNJDx545g9f9MxHfvJMTtQhgoTYkpYCY/NeDv9rp4bwmNSWQmOirHpUXFmn8cQhLOo9KEKE6bqPu29sOtI1mPPbQiPTQ3pAEOSDwn/RC/aska1CRnawohTG6t0Jh8S/gYv2rLDGRNqYGH8d7cJFr8nJAhHsBCtz3HYhAzhX8wQhIOUKFofosKEKve4BOETVIpWhQkJgrCATEgQDkMmJAiHIRMShMOoMKHKPS5B+ASVolVhQpWf9hKET1ApWjIhQQhQKVoyIUEIUClaMiFBCFApWrEJb16+emHXEV+1j0f9he+0225euWbMkiBE+ES90qKVEKrYhIiVevv/vvWTRn/hTZQSZ9UrIVQrE36xKPHCrlTH2xcLE+XmRgQnTqlXWqhWJkTc4uKjjrdv/50qNzciOHFKvdJCLTcm3LZwdXZ2dm5u7okTJ86dOyf8JkmCcDunXmmhlhsTuuYsyMzMzMrKysnJwfQKCuh/PiTEOKVeaaGWGxOumz4/JSUlIyMD08PbjFYdkiAMOKVeaaGWGxMmT5u3du1aTA9vM1ju8/LyjEkThAen1Cst1HJjwg2zEzG3pKQkl8uF9xgs9MakCcKDU+qVFiqZkAg0nFKvtFB9bMIlS6a8+eZLfL83TXpuRHAirV6zVkpVSwtV0oQnT2ZWqBD20EPNDf09ejwaE9OGHffqFdO5czv+WrtNem5EcGKt3k6d2oV5qFGj2hNPdN+3bw0/xtD0qrZo0kKVNOGsWeNYocZPP3Xp+/Xpzpz57JQpI/lr7TbpuRHBibV6oc+GDe9ZuHByv35dIOA6de68desIP0zf/NGESLpRo/rVqlXFHF555Tc2KzFdfsLo4Tv1TXpuRHBirV7os12732nH0PCZM1v1A3g16lXNn9WatFBlTLhr12qk/vbbM2rVqlmvXu2ffz6sndKnO3bswOHD+7LjoqKPExKeady4Ph5i69e/e+XKGei8fv3g+PF/RJCoqBovvvjkTz/9L46+Sc+NCE6s1as3Yf/+XSDIH388UOyRKFaUBg3qVKpUMTq6+fbty7VLmKpXrZrZtGlDrD1Dh/YuLNzLR5YWqowJx4wZUL16xLVr+59/fjDcyKfLH8OQGPnUU/02b168dOnUbduWsThw4KJFk/Hgimf05ctf5e9V7MXciODEWr3QZNu2zb766n0ID6qbOnUU63/22T+Eh1cYOfLx1atnwaWhoaEHDyazU1ByREQVLB7Tp4+Ji3sESp49+zk+srRQbZvwhx+ysaNFrjhGlsxa2lmhCfPzd2K2zZrdp4/DOidNGsF+bNOmadeu7fUDtCY9NyI4sVBv8e1HUEbv3jFYANF5/vwvahw0qAcb8913u2DCgQO7sx+h5Lp179KeWrFOduzYmo8sLVTbJly37jVkv2JFwuefp6MhOSzQWBW1dHkTZmWtxCUvvTRcH4d14nLYDw1LK/aZ/O2KvZgbEZxYqLfYY8IHH2yyb98arIGRkdW6dXv46tV9bIeFtVEbhjHasmH4pAN7KDzEXr78kSGytFBtm7Bnz47aG4lGUtJcPl3teOfOtzFmxoyx+jisc9iwPtgfsgZ787cr9mJuRHBiod7i3+4J2Yqyfv187I9wgF2fNuzhh1vef389dmww4YQJf8Lg77/fY4gsLVR7Jvzmm61YtadMGfn11/9i7ejRd/GuAGfy6WrHZ89ux+KOB3F9qHPndqCzX78uhlvwTXpuRHBipl7W9Cbcs+cfsBOWxNOnP8DBqFG/Z/14ssP+UKhqtPbtW9x1VxQfWVqo9kw4f/5EmBDe03fCSOiE04pNTIg2fHhfTHLIkF67d7+TkvJ6RsZCdGJjCQNPmzb62DHX/v3I/C+G27EmPTciODFTL2vQZJMm927dugx6a9myMVaCQ4fWo79v385RUTWWLp2KHyFUyDU9fQG7BEquWDF83rwXTp16f86c8fBnQsIzfGRpodozYatWD/TqFWPoTEtLRMaJiZNwHB/fITa2LevXH1+5snfw4J7wKkZGRFSZO/fP6MSz+JgxAzAldGKS2huPoUnPjQhOzNTLGjTJ9lDYEA4Y0C05+ddN0PnzO/v0iYUncap69YgFC17WLoEJo6Ob4wEVpzBg6NDe7LcahiYtVHsm9LJhlc/L26L/vWKx5/czJ09msg+phE16bkRw4o16Cwv38hLFEoIFo9izseI/j9GatFCVmlCuSc+NCE6cUq+0UMmERKDhlHqlhUomJAINp9QrLVQyIRFoOKVeaaGSCYlAwyn1SguVTEgEGk6pV1qoZEIi0HBKvdJCJRMSgYZT6pUWqpUJv1iYiLiON1ZnQ2JuRHDilHqlhWplQr9qEnMjghNn1SshVLEJb165dnH3EdZ2LUt+b/5b7878W/K0eQ62pBWr1tr8YmMiOHFWvRJCFZtQT25uLgydkZGBuEmOYvcr/gnCEfXaFWrJJsR6mpOTg4hwtstR7Ba7IQhH1GtXqCWbEFZGLHgaa2uWo9gt+0YQjqjXrlBLNiGiwM0Ih6fbE46CBJAGkkFKRUVFxkQJgsMR9doVaskmJAiiTCETEoTDkAkJwmHIhAThMGRCgnAYMiFBOAyZkCAchkxIEA5DJiQIhyETEoTDkAkJwmHIhAThMP8PSlImtX3xowQAAAAASUVORK5CYII=")&.first&.to_s).to eq "image/png"
  end
end
