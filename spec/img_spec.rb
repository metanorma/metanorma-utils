require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Utils do
  context "recognises data uris" do
    it "where the content is an existing file at a relative path" do
      expect(Metanorma::Utils.datauri("spec/fixtures/rice_image1.png"))
        .to eq Metanorma::Utils.encode_datauri("spec/fixtures/rice_image1.png")
    end

    it "where the content is an existing file at an absolute path" do
      expect(Metanorma::Utils.datauri(File.expand_path("spec/fixtures/rice_image1.png")))
        .to eq Metanorma::Utils.encode_datauri("spec/fixtures/rice_image1.png")
    end

    it "where the content is a relative file path pointing to a bogus file" do
      expect(Metanorma::Utils.datauri("spec/fixtures/bogus.png"))
        .to eq "spec/fixtures/bogus.png"
    end

    it "where the content is an absolute file path pointing to a bogus file" do
      expect(Metanorma::Utils.datauri("D:/spec/fixtures/bogus.png"))
        .to eq "D:/spec/fixtures/bogus.png"
    end

    it "where the content is a data/image URI" do
      expect(Metanorma::Utils.datauri("data1:img/gif,base64,ABBC"))
        .to eq "data1:img/gif,base64,ABBC"
    end

    it "where the content is an URL" do
      expect(Metanorma::Utils.datauri("https://example.com/image.png"))
        .to eq "https://example.com/image.png"
    end
  end

  it "recognises data uris" do
    expect(Metanorma::Utils.datauri?("data:img/gif,base64,ABBC"))
      .to eq true
    expect(Metanorma::Utils.datauri?("data1:img/gif,base64,ABBC"))
      .to eq false
  end

  it "recognises uris" do
    expect(Metanorma::Utils.url?("mailto://ABC"))
      .to eq true
    expect(Metanorma::Utils.url?("http://ABC"))
      .to eq true
    expect(Metanorma::Utils.url?("D:/ABC"))
      .to eq false
    expect(Metanorma::Utils.url?("/ABC"))
      .to eq false
  end

  it "recognises absolute file locations" do
    expect(Metanorma::Utils.absolute_path?("D:/a.html"))
      .to eq true
    expect(Metanorma::Utils.absolute_path?("/a.html"))
      .to eq true
    expect(Metanorma::Utils.absolute_path?("a.html"))
      .to eq false
  end

  it "rewrites SVGs" do
    FileUtils.cp("spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg1.svg")
    FileUtils.cp("spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg2.svg")
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
    expect(xmlpp(xmldoc.to_xml.gsub(%r{<image.*?</image>}m, "<image/>")
.gsub(%r{<style.*?</style>}m, "<style/>")))
      .to be_equivalent_to xmlpp(<<~OUTPUT)
            <?xml version='1.0'?>
        <standard-document type='semantic' version='1.8.2'>
          <bibdata type='standard'>
            <title language='en' format='text/plain'>Document title</title>
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
            <svgmap id='_d5b5049a-dd53-4ea0-bc6f-e8773bd59052'>
              <target href='mn://action_schema'>
                <xref target='ref1'>Computer</xref>
              </target>
            </svgmap>
            <figure>
             <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000001' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
                <style/>
                <image/>
                <a xlink:href='#ref1' xlink:dummy='Layer_1_000000001'>
                  <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
                </a>
                <a xlink:href='mn://basic_attribute_schema'>
                  <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
                </a>
                <a xlink:href='mn://support_resource_schema'>
                  <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
                </a>
              </svg>
            </figure>
            <svgmap id='_60dadf08-48d4-4164-845c-b4e293e00abd'>
              <figure>
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000002' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
                  <style/>
                  <image/>
                  <a xlink:href='mn://action_schema'  xlink:dummy='Layer_1_000000002'>
                    <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
                  </a>
                  <a xlink:href='http://www.example.com'>
                    <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
                  </a>
                  <a xlink:href='mn://support_resource_schema'>
                    <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
                  </a>
                </svg>
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
            <figure>
            <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000003' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
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
              <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000004' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
                  <style/>
                  <image/>
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
  end

  it "rewrites SVGs with namespaces" do
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg1.svg"
    FileUtils.cp "spec/fixtures/action_schemaexpg1.svg",
                 "action_schemaexpg2.svg"
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
    expect(xmlpp(xmldoc.to_xml.gsub(%r{<image.*?</image>}m, "<image/>")))
      .to be_equivalent_to xmlpp(<<~OUTPUT)
                <?xml version='1.0'?>
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
                     <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000001' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
                     <style type='text/css'>
           #Layer_1_000000001 { fill:none } svg[id='Layer_1_000000001'] {
          fill:none } .st0{fill:none;stroke:#000000;stroke-miterlimit:10;}
        </style>
                       <image/>
                       <a xlink:href='#ref1' xlink:dummy='Layer_1_000000001'>
                         <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
                       </a>
                       <a xlink:href='mn://basic_attribute_schema'>
                         <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
                       </a>
                       <a xlink:href='mn://support_resource_schema'>
                         <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
                       </a>
                     </svg>
              </figure>
              <svgmap id='_60dadf08-48d4-4164-845c-b4e293e00abd'>
                <figure>
                <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1_000000002' x='0px' y='0px' viewBox='0 0 595.28 841.89' style='enable-background:new 0 0 595.28 841.89;' xml:space='preserve'>
                <style type='text/css'>
           #Layer_1_000000002 { fill:none } svg[id='Layer_1_000000002'] {
          fill:none } .st0{fill:none;stroke:#000000;stroke-miterlimit:10;}
        </style>
                         <image/>
                         <a xlink:href='mn://action_schema' xlink:dummy='Layer_1_000000002'>
                           <rect x='123.28' y='273.93' class='st0' width='88.05' height='41.84'/>
                         </a>
                         <a xlink:href='http://www.example.com'>
                           <rect x='324.69' y='450.52' class='st0' width='132.62' height='40.75'/>
                         </a>
                         <a xlink:href='mn://support_resource_schema'>
                           <rect x='324.69' y='528.36' class='st0' width='148.16' height='40.75'/>
                         </a>
                       </svg>
                </figure>
              <target href="mn://support_resource_schema"><eref type="express" bibitemid="express_action_schema" citeas=""><localityStack><locality type="anchor"><referenceFrom>action_schema.basic</referenceFrom></locality></localityStack>Coffee</eref></target></svgmap></sections>
                     </standard-document>
      OUTPUT
  end

  it "generates data uris" do
    expect(Metanorma::Utils.datauri("data:xyz")).to eq "data:xyz"
    expect(Metanorma::Utils.datauri("spec/fixtures/rice_image1.png")).to be_equivalent_to "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZAAAAGQCAYAAACAvzbMAAAABmJLR0QA/wD/AP+gvaeTAAAEzUlEQVR4nO3dz4tVZRzH8fedacogMCjHoiBop1RaOzF/QAv7QUIYZdCq/oQo+hdC10FRbVtVBC0r09y0iZAmoVwWRRaMBZlKnhZ3UlEwnVFnhvt6wQPnnnOeh8/m8r0P9zznKQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC42HT1RPVOdbT6c6Edrd5euDa9bOkAWJF2V3PVUA2jGtbfPG6jhXMLba56ahlzArBCTFf7q2GqhhfXNxzY3HB6R8Owc9xO72j4fHPDC7Pjexq3fZmNMOFGyx0Altn+6pV1Mw0fPtDo0bWXv/nLE7Xn24bjZxot9H31BmSEFUkBYZLtrj6+c6bhq0ca3X/rlXU6drK2fN3w27iIPF19ch0zwoqlgDCpbqqOTNWGgw/X/808LnZovnZ+U0N9Vz1Ynb0OGWFFm1ruALBMdlUb9q6/+uJRtf32en62qo2Nn86CiaOAMKmerXr5rsUP8NLd5w6fWXIaWIUUECbV1qqti5h9/Gfb+b7blpwGViEFhEl177qZumUJ34A1U3XHTFX3XKNMsKooIAAsigLCpPrx+Jk6tYRnp/4+W7+fqeqna5QJVhUFhEl1uOrwicUPcGj+/OGS08AqpIAwqT6oevfnxQ/w3i/nDj9achpYhSwkZFJNV0dGtfGLzeN1HVfjwHw9Nl5IOFc9lIWETCAzECbVP9XrQ7VnruHYySvv+MPJem6uYRh/fC3FgwnlbaJMsu+r2/4629b3f23YsrbRfWsu3+HgfO06cu49WPuqN29ATgBWoOnGhWCYqmHvbMNnmxpObT//OvdT2xs+3TS+dsHeIG/kBxgA1ZNdsKFUF2wo1aUbSj2+bCkBWJGmGheHtxoXij8W2tzCuV353xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAS/wLBh+fQNux/v8AAAAASUVORK5CYII="
    expect(Metanorma::Utils.datauri("rice_image1.png",
                                    "spec/fixtures")).to be_equivalent_to "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZAAAAGQCAYAAACAvzbMAAAABmJLR0QA/wD/AP+gvaeTAAAEzUlEQVR4nO3dz4tVZRzH8fedacogMCjHoiBop1RaOzF/QAv7QUIYZdCq/oQo+hdC10FRbVtVBC0r09y0iZAmoVwWRRaMBZlKnhZ3UlEwnVFnhvt6wQPnnnOeh8/m8r0P9zznKQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC42HT1RPVOdbT6c6Edrd5euDa9bOkAWJF2V3PVUA2jGtbfPG6jhXMLba56ahlzArBCTFf7q2GqhhfXNxzY3HB6R8Owc9xO72j4fHPDC7Pjexq3fZmNMOFGyx0Altn+6pV1Mw0fPtDo0bWXv/nLE7Xn24bjZxot9H31BmSEFUkBYZLtrj6+c6bhq0ca3X/rlXU6drK2fN3w27iIPF19ch0zwoqlgDCpbqqOTNWGgw/X/808LnZovnZ+U0N9Vz1Ynb0OGWFFm1ruALBMdlUb9q6/+uJRtf32en62qo2Nn86CiaOAMKmerXr5rsUP8NLd5w6fWXIaWIUUECbV1qqti5h9/Gfb+b7blpwGViEFhEl177qZumUJ34A1U3XHTFX3XKNMsKooIAAsigLCpPrx+Jk6tYRnp/4+W7+fqeqna5QJVhUFhEl1uOrwicUPcGj+/OGS08AqpIAwqT6oevfnxQ/w3i/nDj9achpYhSwkZFJNV0dGtfGLzeN1HVfjwHw9Nl5IOFc9lIWETCAzECbVP9XrQ7VnruHYySvv+MPJem6uYRh/fC3FgwnlbaJMsu+r2/4629b3f23YsrbRfWsu3+HgfO06cu49WPuqN29ATgBWoOnGhWCYqmHvbMNnmxpObT//OvdT2xs+3TS+dsHeIG/kBxgA1ZNdsKFUF2wo1aUbSj2+bCkBWJGmGheHtxoXij8W2tzCuV353xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAS/wLBh+fQNux/v8AAAAASUVORK5CYII="
    expect(Metanorma::Utils.datauri2mime("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZAAAAGQCAYAAACAvzbMAAAABmJLR0QA/wD/AP+gvaeTAAAEzUlEQVR4nO3dz4tVZRzH8fedacogMCjHoiBop1RaOzF/QAv7QUIYZdCq/oQo+hdC10FRbVtVBC0r09y0iZAmoVwWRRaMBZlKnhZ3UlEwnVFnhvt6wQPnnnOeh8/m8r0P9zznKQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC42HT1RPVOdbT6c6Edrd5euDa9bOkAWJF2V3PVUA2jGtbfPG6jhXMLba56ahlzArBCTFf7q2GqhhfXNxzY3HB6R8Owc9xO72j4fHPDC7Pjexq3fZmNMOFGyx0Altn+6pV1Mw0fPtDo0bWXv/nLE7Xn24bjZxot9H31BmSEFUkBYZLtrj6+c6bhq0ca3X/rlXU6drK2fN3w27iIPF19ch0zwoqlgDCpbqqOTNWGgw/X/808LnZovnZ+U0N9Vz1Ynb0OGWFFm1ruALBMdlUb9q6/+uJRtf32en62qo2Nn86CiaOAMKmerXr5rsUP8NLd5w6fWXIaWIUUECbV1qqti5h9/Gfb+b7blpwGViEFhEl177qZumUJ34A1U3XHTFX3XKNMsKooIAAsigLCpPrx+Jk6tYRnp/4+W7+fqeqna5QJVhUFhEl1uOrwicUPcGj+/OGS08AqpIAwqT6oevfnxQ/w3i/nDj9achpYhSwkZFJNV0dGtfGLzeN1HVfjwHw9Nl5IOFc9lIWETCAzECbVP9XrQ7VnruHYySvv+MPJem6uYRh/fC3FgwnlbaJMsu+r2/4629b3f23YsrbRfWsu3+HgfO06cu49WPuqN29ATgBWoOnGhWCYqmHvbMNnmxpObT//OvdT2xs+3TS+dsHeIG/kBxgA1ZNdsKFUF2wo1aUbSj2+bCkBWJGmGheHtxoXij8W2tzCuV353xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAS/wLBh+fQNux/v8AAAAASUVORK5CYII=")&.first&.to_s).to eq "image/png"
    expect(Metanorma::Utils.datauri("spec/fixtures/rice_image0.png")).to be_equivalent_to "spec/fixtures/rice_image0.png"
    expect do
      Metanorma::Utils.datauri("spec/fixtures/rice_image0.png")
    end.to output(%r{Image specified at `spec/fixtures/rice_image0\.png` does not exist\.}).to_stderr
  end

  it "resizes images with missing or auto sizes" do
    image = Nokogiri::XML("<img src='spec/19160-8.jpg'/>").root
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "20"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [20, 65]
    image.delete("width")
    image["height"] = "50"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [15, 50]
    image.delete("height")
    image["width"] = "500"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image.delete("width")
    image["height"] = "500"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "20"
    image["height"] = "auto"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [20, 65]
    image["width"] = "auto"
    image["height"] = "50"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [15, 50]
    image["width"] = "500"
    image["height"] = "auto"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "auto"
    image["height"] = "500"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "auto"
    image["height"] = "auto"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
  end

  it "converts percentage sizes of images" do
    image = Nokogiri::XML("<img src='spec/19160-8.jpg'/>").root
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[919, 3000], [919, 3000]]
    image["width"] = "20.4"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[20, 0], [919, 3000]]
    image["height"] = "auto"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[20, 0], [919, 3000]]
    image.delete("width")
    image["height"] = "20.4"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[0, 20], [919, 3000]]
    image["width"] = "auto"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[0, 20], [919, 3000]]
    image["height"] = "30%"
    image["width"] = "50%"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[459, 900], [919, 3000]]
  end

  it "resizes SVG with missing or auto sizes" do
    image = Nokogiri::XML(File.read("spec/odf.svg")).root
    Metanorma::Utils.image_resize(image, "spec/odf.svg", 100, 100)
    expect(image.attributes["viewBox"].value).to eq "0 0 100 100"
  end
end
