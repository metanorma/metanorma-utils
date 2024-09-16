require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Utils do
  # not testing Asciidoctor log extraction here
  it "generates log" do
    class WithId
      attr_accessor :id, :parent

      def to_s
        "ID: #{@id}"
      end
    end

    class WithLineno
      attr_accessor :lineno

      def to_s
        "Line: #{@lineno}"
      end
    end

    class WithLine
      attr_accessor :line

      def to_s
        "Line: #{@line}"
      end
    end

    id1 = WithId.new
    id2 = WithId.new
    id2.id = "B"
    id2.parent = id1
    id3 = WithId.new
    id3.parent = id1

    li1 = WithLineno.new
    li1.lineno = "12"
    li2 = WithLineno.new
    li3 = WithLine.new
    li3.line = "13"
    li4 = WithLine.new

    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <a>
      <b id="xyz">
      c
      </b></a></xml>
    INPUT
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", nil, "Message 1", severity: 0)
    log.add("Category 1", "node", "Message 2", severity: 1)
    log.add("Category 2", xml.at("//xml/a/b"), "Message 3", severity: 2)
    log.add("Category 2", xml.at("//xml/a"), "Message 4", severity: 0)
    log.add("Category 2", xml.at("//xml/a"), "Message 5 :: Context",
            severity: 1)
    log.add("Category 3", id1, "Message 6.1", severity: 2)
    log.add("Category 3", id2, "Message 6.2")
    log.add("Category 3", id3, "Message 6.3")
    log.add("Category 4", li1, "XML Line 1212:40, Message 7.1")
    log.add("Category 4", li2, "Message 7.2")
    log.add("Category 4", li3, "Message 7.3")
    log.add("Category 4", li4, "Message 7.4")
    log.mapid("xyz", "abc")
    log.mapid("abc", "def")
    log.write("log.txt")
    expect(log.abort_messages).to be_equivalent_to ["Message 1", "Message 4"]
    expect(File.exist?("log.err.html")).to be true
    expect(File.exist?("log.txt")).to be false
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 0: <b>1</b> errors; Severity 1: <b>1</b> errors</p></li>

       <li><p><b><a href="#Category_2">Category 2</a></b>: Severity 0: <b>1</b> errors; Severity 1: <b>1</b> errors; Severity 2: <b>1</b> errors</p></li>

       <li><p><b><a href="#Category_3">Category 3</a></b>: Severity 2: <b>3</b> errors</p></li>

       <li><p><b><a href="#Category_4">Category 4</a></b>: Severity 2: <b>4</b> errors</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity0"><td></td><th><code>--</code></th><td>Message 1</td><td><pre></pre></td><td>0</td></tr>
      <tr class="severity1"><td></td><th><code>node</code></th><td>Message 2</td><td><pre></pre></td><td>1</td></tr>
      </tbody></table>
      <h2 id="Category_2">Category 2</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity0"><td>000002</td><th><code>--</code></th><td>Message 4</td><td><pre>&lt;a&gt;
      &lt;b id=&quot;xyz&quot;&gt;
      c
      &lt;/b&gt; &lt;/a&gt;</pre></td><td>0</td></tr>
      <tr class="severity1"><td>000002</td><th><code>--</code></th><td>Message 5</td><td><pre>Context</pre></td><td>1</td></tr>
      <tr class="severity2"><td>000003</td><th><code><a href='#{File.join('.', 'log.html')}#def'>def</a></code></th><td>Message 3</td><td><pre>&lt;b id=&quot;xyz&quot;&gt;
      c
      &lt;/b&gt;</pre></td><td>2</td></tr>
      </tbody></table>
      <h2 id="Category_3">Category 3</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2"><td></td><th><code>--</code></th><td>Message 6.1</td><td><pre>ID: </pre></td><td>2</td></tr>
      <tr class="severity2"><td></td><th><code>--</code></th><td>Message 6.3</td><td><pre>ID: </pre></td><td>2</td></tr>
      <tr class="severity2"><td></td><th><code><a href='#{File.join('.', 'log.html')}#B'>B</a></code></th><td>Message 6.2</td><td><pre>ID: B</pre></td><td>2</td></tr>
      </tbody></table>
      <h2 id="Category_4">Category 4</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2"><td></td><th><code>??</code></th><td>Message 7.2</td><td><pre>Line: </pre></td><td>2</td></tr>
      <tr class="severity2"><td></td><th><code>??</code></th><td>Message 7.4</td><td><pre>Line: </pre></td><td>2</td></tr>
      <tr class="severity2"><td>000013</td><th><code>XML Line 000013</code></th><td>Message 7.3</td><td><pre>Line: 13</pre></td><td>2</td></tr>
      <tr class="severity2"><td>1212</td><th><code>Asciidoctor Line 000012</code></th><td>XML Line 1212:40, Message 7.1</td><td><pre>Line: 12</pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end

  it "sets log file location" do
    FileUtils.rm_f("metanorma.err.html")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", nil, "Message 1", severity: 0)
    log.write
    expect(File.exist?("metanorma.err.html")).to be true
    FileUtils.rm_f("metanorma.err.html")

    FileUtils.rm_f("log.html")
    log.write("log.html")
    expect(File.exist?("log.err.html")).to be true
    FileUtils.rm_f("log.err.html")

    FileUtils.rm_f("spec/log.html")
    log.write("spec/log.html")
    expect(File.exist?("spec/log.err.html")).to be true
    FileUtils.rm_f("spec/log.err.html")

    FileUtils.rm_f("log.err.html")
    log.save_to("log.html")
    log.write
    expect(File.exist?("log.err.html")).to be true
    FileUtils.rm_f("log.err.html")

    FileUtils.rm_f("spec/log.err.html")
    log.save_to("log.html", "spec")
    log.write
    expect(File.exist?("spec/log.err.html")).to be true
    FileUtils.rm_f("spec/log.err.html")

    FileUtils.rm_f("spec/log.err.html")
    FileUtils.rm_f("spec/log1.err.html")
    log.save_to("log.html", "spec")
    log.write("spec/log1.err.html")
    expect(File.exist?("spec/log.err.html")).to be false
    expect(File.exist?("spec/log1.err.html")).to be true
    FileUtils.rm_f("spec/log.err.html")
    FileUtils.rm_f("spec/log1.err.html")
  end

  it "suppresses errors from screen display" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new
    expect { log.add("Category 1", nil, "A") }
      .to output("Category 1: A\n").to_stderr
    expect { log.add("Category 1", nil, "A", display: false) }
      .not_to output("Category 1: A\n").to_stderr
    expect { log.add("Metanorma XML Syntax", nil, "A") }
      .not_to output("Metanorma XML Syntax: A\n").to_stderr
    expect { log.add("Relaton", nil, "A") }
      .not_to output("Relaton: A\n").to_stderr
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head>
      <body><h1>./log.err.html errors</h1>
       <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>2</b> errors</p></li>
       <li><p><b><a href="#Metanorma_XML_Syntax">Metanorma XML Syntax</a></b>: Severity 2: <b>1</b> errors</p></li>
       <li><p><b><a href="#Relaton">Relaton</a></b>: Severity 2: <b>1</b> errors</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity2">
       <td></td><th><code>--</code></th>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       <tr class="severity2">
       <td></td><th><code>--</code></th>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       </tbody></table>
       <h2 id="Metanorma_XML_Syntax">Metanorma XML Syntax</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity2">
       <td></td><th><code>--</code></th>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       </tbody></table>
       <h2 id="Relaton">Relaton</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity2">
       <td></td><th><code>--</code></th>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       </tbody></table>
       </body></html>
    OUTPUT
  end

  it "suppresses errors from log" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new
    log.suppress_log = { severity: [2, 3],
                         category: ["Category 1", "Category 2"] }
    expect { log.add("Category 1", nil, "A", severity: 1) }
      .not_to output("Category 1: A\n").to_stderr
    expect { log.add("Category 1", nil, "B", severity: 2) }
      .not_to output("Category 1: B\n").to_stderr
    expect { log.add("Category 1", nil, "C", severity: 3) }
      .not_to output("Category 1: C\n").to_stderr
    expect { log.add("Category 2", nil, "A", severity: 1) }
      .not_to output("Category 2: A\n").to_stderr
    expect { log.add("Category 2", nil, "B", severity: 2) }
      .not_to output("Category 2: B\n").to_stderr
    expect { log.add("Category 2", nil, "C", severity: 3) }
      .not_to output("Category 2: C\n").to_stderr
    expect { log.add("Category 3", nil, "A", severity: 1) }
      .to output("Category 3: A\n").to_stderr
    expect { log.add("Category 3", nil, "B", severity: 2) }
      .not_to output("Category 3: B\n").to_stderr
    expect { log.add("Category 3", nil, "C", severity: 3) }
      .not_to output("Category 3: C\n").to_stderr
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head>
      <body><h1>./log.err.html errors</h1>
       <ul><li><p><b><a href="#Category_3">Category 3</a></b>: Severity 1: <b>1</b> errors</p></li>
       </ul>
       <h2 id="Category_3">Category 3</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity1">
       <td></td><th><code>--</code></th>
       <td>A</td><td><pre></pre></td><td>1</td></tr>
       </tbody></table>
       </body></html>
    OUTPUT
  end

  it "deals with illegal characters in log" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", nil, "é\xc2")
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>1</b> errors</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2"><td></td><th><code>--</code></th><td>é�</td><td><pre></pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end

  it "deals with long strings in log" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new
    log.add("Category 1",
            "ID AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB")
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>1</b> errors</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2">
      <td></td><th><code><a href='#{File.join('.', 'log.html')}#AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'>AAAAAAAAAAAAAAAAAAAA­AAAAAAAAAAAAAAAAAAAA­AAAAAAAAAAAAAA</a></code></th>
      <td>BBBBBBBBBBBBBBBBBBBB­BBBBBBBBBBBBBBBBBBBB­BBBBBBBB</td><td><pre></pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
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
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new
    log.add("Category 2", xml.at("//xml/a"), "Message 3")
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_2">Category 2</a></b>: Severity 2: <b>1</b> errors</p></li>
      </ul>
      <h2 id="Category_2">Category 2</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2"><td>000002</td><th><code>--</code></th><td>Message 3</td><td><pre>&lt;a&gt;
      The number is &lt;latexmath&gt;\\1&lt;/latexmath&gt; &lt;/a&gt;</pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end
end
