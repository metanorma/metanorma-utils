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

    messages = {
      "FLAVOR_3": { error: "Message 1", severity: 0, category: "Category 1" },
      "BMX_44": { error: "Message 2", severity: 1, category: "Category 1" },
      "FLAVOR_5": { error: "Message 3", severity: 2, category: "Category 2" },
      "FLAVOR_10": { error: "Message 4", severity: 0, category: "Category 2" },
      "FLAVOR_1": { error: "Message 5 :: Context", severity: 1,
                    category: "Category 2" },
      "BMX_4": { error: "Message 6", severity: 1, category: "Category 2" },
      "BMX_3": { error: "Message 6.1", severity: 2, category: "Category 3" },
      "FLAVOR_2": { error: "Message 6.2", severity: 2, category: "Category 3" },
      "FLAVOR_50": { error: "Message 6.3", severity: 2,
                     category: "Category 3" },
      "FLAVOR_49": { error: "XML Line 1212:40, Message 7.1", severity: 2,
                     category: "Category 4" },
      "FLAVOR_48": { error: "Message 7.2", severity: 2,
                     category: "Category 4" },
      "FLAVOR_47": { error: "Message 7.3", severity: 2,
                     category: "Category 4" },
      "FLAVOR_46": { error: "Message 7.4", severity: 2,
                     category: "Category 4" },
    }

    xml = Nokogiri::XML(<<~INPUT)
      <xml>
      <a>
      <b id="xyz">
      c
      </b>
      <c id="abc" anchor="Löwe"/>
      </a></xml>
    INPUT
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new(messages)
    log.add("FLAVOR_3", nil)
    log.add("BMX_44", "node")
    log.add("FLAVOR_5", xml.at("//xml/a/b"))
    log.add("FLAVOR_10", xml.at("//xml/a"))
    log.add("FLAVOR_1", xml.at("//xml/a"))
    log.add("BMX_4", xml.at("//xml/a/c"))
    log.add("BMX_3", id1)
    log.add("FLAVOR_2", id2)
    log.add("FLAVOR_50", id3)
    log.add("FLAVOR_49", li1)
    log.add("FLAVOR_48", li2)
    log.add("FLAVOR_47", li3)
    log.add("FLAVOR_46", li4)
    log.mapid("xyz", "abc")
    log.mapid("abc", "ghi")
    log.write("log.txt")
    expect(log.abort_messages).to be_equivalent_to ["Message 1", "Message 4"]
    expect(log.messages).to be_equivalent_to [
      { error_id: "FLAVOR_3", location: "", severity: 0, error: "Message 1",
        context: "", line: "000000", anchor: nil, id: nil },
      { error_id: "BMX_44", location: "node", severity: 1,
        error: "Message 2", context: nil, line: "000000", anchor: nil, id: nil },
      { error_id: "FLAVOR_5", location: "xyz", severity: 2,
        error: "Message 3", context: "<b id=\"xyz\">\nc\n</b>", line: "000003", anchor: nil, id: "xyz" },
      { error_id: "FLAVOR_10", location: "", severity: 0, error: "Message 4",
        context: "<a>\n<b id=\"xyz\">\nc\n</b>\n<c id=\"abc\" anchor=\"L&#xF6;we\"/>\n</a>", line: "000002", anchor: nil, id: nil },
      { error_id: "FLAVOR_1", location: "", severity: 1, error: "Message 5",
        context: "Context", line: "000002", anchor: nil, id: nil },
      { error_id: "BMX_4", location: "Löwe", severity: 1, error: "Message 6",
        context: "<c id=\"abc\" anchor=\"L&#xF6;we\"/>", line: "000006", anchor: "Löwe", id: "abc" },
      { error_id: "BMX_3", location: "", severity: 2, error: "Message 6.1",
        context: "ID: ", line: "000000", anchor: nil, id: nil },
      { error_id: "FLAVOR_2", location: "B", severity: 2,
        error: "Message 6.2", context: "ID: B", line: "000000", anchor: nil, id: nil },
      { error_id: "FLAVOR_50", location: "", severity: 2,
        error: "Message 6.3", context: "ID: ", line: "000000", anchor: nil, id: nil },
      { error_id: "FLAVOR_49", location: "Asciidoctor Line 000012",
        severity: 2, error: "XML Line 1212:40, Message 7.1", context: "Line: 12", line: "1212", anchor: nil, id: nil },
      { error_id: "FLAVOR_48", location: "??", severity: 2,
        error: "Message 7.2", context: "Line: ", line: "000000", anchor: nil, id: nil },
      { error_id: "FLAVOR_47", location: "XML Line 000013", severity: 2,
        error: "Message 7.3", context: "Line: 13", line: "000013", anchor: nil, id: nil },
      { error_id: "FLAVOR_46", location: "??", severity: 2,
        error: "Message 7.4", context: "Line: ", line: "000000", anchor: nil, id: nil },
    ]
    expect(log.display_messages).to be_equivalent_to <<~OUTPUT
      Category 1:
      \tBMX_44      : Message 2
      \tFLAVOR_3    : Message 1
      Category 2:
      \tBMX_4       : Message 6
      \tFLAVOR_1    : Message 5 :: Context
      \tFLAVOR_5    : Message 3
      \tFLAVOR_10   : Message 4
      Category 3:
      \tBMX_3       : Message 6.1
      \tFLAVOR_2    : Message 6.2
      \tFLAVOR_50   : Message 6.3
      Category 4:
      \tFLAVOR_46   : Message 7.4
      \tFLAVOR_47   : Message 7.3
      \tFLAVOR_48   : Message 7.2
      \tFLAVOR_49   : XML Line 1212:40, Message 7.1
    OUTPUT
    expect(File.exist?("log.err.html")).to be true
    expect(File.exist?("log.txt")).to be false
    file = File.read("log.err.html", encoding: "utf-8")
    # {File.join('.', 'log.html')}
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 0: <b>1</b> error; Severity 1: <b>1</b> error</p></li>
      <li><p><b><a href="#Category_2">Category 2</a></b>: Severity 0: <b>1</b> error; Severity 1: <b>2</b> errors; Severity 2: <b>1</b> error</p></li>

      <li><p><b><a href="#Category_3">Category 3</a></b>: Severity 2: <b>3</b> errors</p></li>

      <li><p><b><a href="#Category_4">Category 4</a></b>: Severity 2: <b>4</b> errors</p></li>
      </ul>
       <h2 id="Category_1">Category 1</h2>
       <table border="1">
       <thead><th width="5%">Line</th><th width="20%">ID</th><th width="10%">Error</th>
       <th width="20%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
       <tbody>
       <tr class="severity0">
       <td></td><th><code>--</code></th><td>FLAVOR_3</td>
       <td>Message 1</td><td><pre></pre></td><td>0</td></tr>
       <tr class="severity1">
       <td></td><th><code>node</code></th><td>BMX_44</td>
       <td>Message 2</td><td><pre></pre></td><td>1</td></tr>
       </tbody></table>
       <h2 id="Category_2">Category 2</h2>
       <table border="1">
       <thead><th width="5%">Line</th><th width="20%">ID</th><th width="10%">Error</th>
       <th width="20%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
       <tbody>
       <tr class="severity0">
       <td>000002</td><th><code>--</code></th><td>FLAVOR_10</td>
       <td>Message 4</td><td><pre>&lt;a&gt;
       &lt;b id=&quot;xyz&quot;&gt;
       c
       &lt;/b&gt;
       &lt;c id=&quot;abc&quot; anchor=&quot;L&amp;#xF6;we&quot;/&gt;</pre></td><td>0</td></tr>
       <tr class="severity1">
       <td>000002</td><th><code>--</code></th><td>FLAVOR_1</td>
       <td>Message 5</td><td><pre>Context</pre></td><td>1</td></tr>
       <tr class="severity2">
       <td>000003</td><th><code><a href='#{File.join('.', 'log.html')}#ghi'>ghi</a></code></th><td>FLAVOR_5</td>
       <td>Message 3</td><td><pre>&lt;b id=&quot;xyz&quot;&gt;
       c
       &lt;/b&gt;</pre></td><td>2</td></tr>
       <tr class="severity1">
       <td>000006</td><th><code><a href='#{File.join('.', 'log.html')}#Löwe'>Löwe</a></code></th><td>BMX_4</td>
       <td>Message 6</td><td><pre>&lt;c id=&quot;abc&quot; anchor=&quot;L&amp;#xF6;we&quot;/&gt;</pre></td><td>1</td></tr>
       </tbody></table>
       <h2 id="Category_3">Category 3</h2>
       <table border="1">
       <thead><th width="5%">Line</th><th width="20%">ID</th><th width="10%">Error</th>
       <th width="20%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
       <tbody>
       <tr class="severity2">
       <td></td><th><code>--</code></th><td>BMX_3</td>
       <td>Message 6.1</td><td><pre>ID: </pre></td><td>2</td></tr>
       <tr class="severity2">
       <td></td><th><code>--</code></th><td>FLAVOR_50</td>
       <td>Message 6.3</td><td><pre>ID: </pre></td><td>2</td></tr>
       <tr class="severity2">
       <td></td><th><code><a href='#{File.join('.', 'log.html')}#B'>B</a></code></th><td>FLAVOR_2</td>
       <td>Message 6.2</td><td><pre>ID: B</pre></td><td>2</td></tr>
       </tbody></table>
       <h2 id="Category_4">Category 4</h2>
       <table border="1">
       <thead><th width="5%">Line</th><th width="20%">ID</th><th width="10%">Error</th>
       <th width="20%">Message</th><th width="40%">Context</th><th width="5%">Severity</th></thead>
       <tbody>
       <tr class="severity2">
       <td></td><th><code>??</code></th><td>FLAVOR_48</td>
       <td>Message 7.2</td><td><pre>Line: </pre></td><td>2</td></tr>
       <tr class="severity2">
       <td></td><th><code>??</code></th><td>FLAVOR_46</td>
       <td>Message 7.4</td><td><pre>Line: </pre></td><td>2</td></tr>
       <tr class="severity2">
       <td>000013</td><th><code>XML Line 000013</code></th><td>FLAVOR_47</td>
       <td>Message 7.3</td><td><pre>Line: 13</pre></td><td>2</td></tr>
       <tr class="severity2">
       <td>1212</td><th><code>Asciidoctor Line 000012</code></th><td>FLAVOR_49</td>
       <td>XML Line 1212:40, Message 7.1</td><td><pre>Line: 12</pre></td><td>2</td></tr>
       </tbody></table>
       </body></html>
    OUTPUT
  end

  it "log non-existent error" do
    begin
      log = Metanorma::Utils::Log.new(
        "A": { error: "Message 1", severity: 0, category: "Category 1" },
      )
      expect do
        log.add("B", nil)
      end.to raise_error(RuntimeError)
    rescue SystemExit, RuntimeError
    end

    begin
      log = Metanorma::Utils::Log.new(
        "A": { error: "Message 1", severity: 2, category: "Category 1" },
      )
      log.add_msg({
                    "B": { error: "Message 2", severity: 1,
                           category: "Category 2" },
                  })
      expect do
        log.add("A", nil)
        log.add("B", nil)
      end.not_to raise_error(SystemExit)
    rescue SystemExit, RuntimeError
    end
    expect(log.messages).to be_equivalent_to [
      { error_id: "A", location: "", severity: 2, error: "Message 1",
        context: "", line: "000000", anchor: nil, id: nil },
      { error_id: "B", location: "", severity: 1, error: "Message 2",
        context: "", line: "000000", anchor: nil, id: nil },
    ]
  end

  it "sets log file location" do
    FileUtils.rm_f("metanorma.err.html")
    log = Metanorma::Utils::Log.new(
      "A": { error: "Message 1", severity: 0, category: "Category 1" },
    )
    log.add("A", nil)
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

  it "interpolates text in error messages" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new(
      "A": { error: "A %s B %s", severity: 2, category: "Category 1" },
    )
    FileUtils.rm_f("log.err.html")
    expect { log.add("A", nil) }
      .to output("Category 1: A  B \n").to_stderr
    expect(log.messages).to be_equivalent_to [
      { error_id: "A", location: "", severity: 2, error: "A  B ", context: "",
        line: "000000", anchor: nil, id: nil },
    ]
    log.write("log.txt")
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>1</b> error</p></li>
      </ul>
      <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2">
      <td></td><th><code>--</code></th><td>A</td>
      <td>A  B </td><td><pre></pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT

    log = Metanorma::Utils::Log.new(
      "A": { error: "A %s B %s", severity: 2, category: "Category 1" },
    )
    FileUtils.rm_f("log.err.html")
    expect { log.add("A", nil, display: true, params: ["foo", "bar"]) }
      .to output("Category 1: A foo B bar\n").to_stderr
    expect(log.messages).to be_equivalent_to [
      { error_id: "A", location: "", severity: 2, error: "A foo B bar",
        context: "", line: "000000", anchor: nil, id: nil },
    ]
    log.write("log.txt")
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>1</b> error</p></li>
      </ul>
      <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2">
      <td></td><th><code>--</code></th><td>A</td>
      <td>A foo B bar</td><td><pre></pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT

    log = Metanorma::Utils::Log.new(
      "A": { error: "A %s B %s", severity: 2, category: "Category 1" },
    )
    expect { log.add("A", nil, display: true, params: [nil, "bar"]) }
      .to output("Category 1: A  B bar\n").to_stderr
  end

  it "suppresses errors from screen display" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new(
      "A": { error: "A", severity: 2, category: "Category 1" },
      "B": { error: "A", severity: 2, category: "Metanorma XML Syntax" },
      "C": { error: "A", severity: 2, category: "Relaton" },
    )
    expect { log.add("A", nil) }
      .to output("Category 1: A\n").to_stderr
    expect { log.add("A", nil, display: false) }
      .not_to output("Category 1: A\n").to_stderr
    expect { log.add("B", nil) }
      .not_to output("Metanorma XML Syntax: A\n").to_stderr
    expect { log.add("C", nil) }
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
       <li><p><b><a href="#Metanorma_XML_Syntax">Metanorma XML Syntax</a></b>: Severity 2: <b>1</b> error</p></li>
       <li><p><b><a href="#Relaton">Relaton</a></b>: Severity 2: <b>1</b> error</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity2">
       <td></td><th><code>--</code></th><td>A</td>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       <tr class="severity2">
       <td></td><th><code>--</code></th><td>A</td>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       </tbody></table>
       <h2 id="Metanorma_XML_Syntax">Metanorma XML Syntax</h2>
       <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2">
      <td></td><th><code>--</code></th><td>B</td>
      <td>A</td><td><pre></pre></td><td>2</td></tr>
      </tbody></table>
       <h2 id="Relaton">Relaton</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity2">
       <td></td><th><code>--</code></th><td>C</td>
       <td>A</td><td><pre></pre></td><td>2</td></tr>
       </tbody></table>
       </body></html>
    OUTPUT
  end

  it "suppresses errors from log" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new(
      "A1": { error: "A", severity: 1, category: "Category 1" },
      "A2": { error: "B", severity: 2, category: "Category 1" },
      "A3": { error: "C", severity: 3, category: "Category 1" },
      "A4": { error: "A", severity: 1, category: "Category 2" },
      "A5": { error: "B", severity: 2, category: "Category 2" },
      "A6": { error: "C", severity: 3, category: "Category 2" },
      "A7": { error: "A", severity: 1, category: "Category 3" },
      "A8": { error: "B", severity: 2, category: "Category 3" },
      "A9": { error: "C", severity: 3, category: "Category 3" },
      "A10": { error: "C", severity: 1, category: "Category 3" },
    )
    log.suppress_log = { severity: 2,
                         category: ["Category 1", "Category 2"],
                         error_ids: ["A10"] }
    expect { log.add("A1", nil) }
      .not_to output("Category 1: A\n").to_stderr
    expect { log.add("A2", nil) }
      .not_to output("Category 1: B\n").to_stderr
    expect { log.add("A3", nil) }
      .not_to output("Category 1: C\n").to_stderr
    expect { log.add("A4", nil) }
      .not_to output("Category 2: A\n").to_stderr
    expect { log.add("A5", nil) }
      .not_to output("Category 2: B\n").to_stderr
    expect { log.add("A6", nil) }
      .not_to output("Category 2: C\n").to_stderr
    expect { log.add("A7", nil) }
      .to output("Category 3: A\n").to_stderr
    expect { log.add("A8", nil) }
      .not_to output("Category 3: B\n").to_stderr
    expect { log.add("A9", nil) }
      .not_to output("Category 3: C\n").to_stderr
    expect { log.add("A10", nil) }
      .not_to output("Category 3: A\n").to_stderr
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head>
      <body><h1>./log.err.html errors</h1>
       <ul><li><p><b><a href="#Category_3">Category 3</a></b>: Severity 1: <b>1</b> error</p></li>
       </ul>
       <h2 id="Category_3">Category 3</h2>
       <table border="1">
      #{TBL_HDR}
       <tbody>
       <tr class="severity1">
       <td></td><th><code>--</code></th><td>A7</td>
       <td>A</td><td><pre></pre></td><td>1</td></tr>
       </tbody></table>
       </body></html>
    OUTPUT
  end

  it "deals with illegal characters in log" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new(
      "A": { error: "é\xc2", severity: 2, category: "Category 1" },
    )
    log.add("A", nil)
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>1</b> error</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2"><td></td><th><code>--</code></th><td>A</td><td>é�</td><td><pre></pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end

  it "deals with long strings in log" do
    FileUtils.rm_f("log.err.html")
    log = Metanorma::Utils::Log.new(
      "A": { error: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
             severity: 2, category: "Category 1" },
    )
    log.add("A",
            "ID AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_1">Category 1</a></b>: Severity 2: <b>1</b> error</p></li>
       </ul>
       <h2 id="Category_1">Category 1</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2">
      <td></td><th><code><a href='#{File.join('.', 'log.html')}#AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'>AAAAAAAAAAAAAAAAAAAA­AAAAAAAAAAAAAAAAAAAA­AAAAAAAAAAAAAA</a></code></th><td>A</td>
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
    log = Metanorma::Utils::Log.new(
      "A": { error: "Message 3", severity: 2, category: "Category 2" },
    )
    log.add("A", xml.at("//xml/a"))
    log.write("log.txt")
    expect(File.exist?("log.err.html")).to be true
    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>./log.err.html errors</title>
      #{HTML_HDR}
      </head><body><h1>./log.err.html errors</h1>
      <ul><li><p><b><a href="#Category_2">Category 2</a></b>: Severity 2: <b>1</b> error</p></li>
      </ul>
      <h2 id="Category_2">Category 2</h2>
      <table border="1">
      #{TBL_HDR}
      <tbody>
      <tr class="severity2">
      <td>000002</td><th><code>--</code></th><td>A</td>
      <td>Message 3</td><td><pre>&lt;a&gt;
      The number is &lt;latexmath&gt;\\1&lt;/latexmath&gt; &lt;/a&gt;</pre></td><td>2</td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end

  it "filters log messages by location ranges" do
    # Create XML document with anchors and ids
    xml = Nokogiri::XML(<<~INPUT)
      <document>
        <section id="sec1" anchor="intro">
          <title id="title1">Introduction</title>
          <para id="para1" anchor="p1">First paragraph</para>
          <para id="para2" anchor="p2">Second paragraph</para>
        </section>
        <section id="sec2" anchor="main">
          <subsection id="subsec1" anchor="sub1">
            <para id="para3" anchor="p3">Nested paragraph</para>
            <para id="para4" anchor="p4">Another nested</para>
          </subsection>
          <para id="para5" anchor="p5">Main section para</para>
        </section>
        <section id="sec3" anchor="conclusion">
          <para id="para6" anchor="p6">Conclusion para</para>
        </section>
      </document>
    INPUT

    # Create messages with various categories and severities
    messages = {}
    (1..25).each do |i|
      error_id = "ERR#{'%02d' % i}"
      messages[error_id.to_sym] = {
        error: "Message #{i}",
        severity: i % 3,
        category: "Category #{(i % 3) + 1}",
      }
    end

    log = Metanorma::Utils::Log.new(messages)

    # Add messages to various locations
    # Messages in intro section (will be suppressed by first rule)
    log.add("ERR01", xml.at("//section[@anchor='intro']"))
    log.add("ERR02", xml.at("//para[@id='para1']"))
    log.add("ERR03", xml.at("//para[@id='para2']"))

    # Messages in main section, within sub1 to p5 range
    # (will be suppressed by second rule)
    log.add("ERR04", xml.at("//subsection[@anchor='sub1']"))
    log.add("ERR05", xml.at("//para[@id='para3']"))
    log.add("ERR06", xml.at("//para[@id='para4']"))
    log.add("ERR07", xml.at("//para[@id='para5']"))

    # Messages in conclusion section
    # (will be selectively suppressed by third rule)
    log.add("ERR08", xml.at("//section[@anchor='conclusion']")) # Type A error
    log.add("ERR09", xml.at("//para[@id='para6']")) # Type B error
    log.add("ERR10", xml.at("//para[@id='para6']")) # Type C error -
    # not suppressed

    # Messages without node location (string locations - should not be filtered)
    log.add("ERR11", "Manual location 1")
    log.add("ERR12", "Manual location 2")

    # Messages with nil location (should not be filtered)
    log.add("ERR13", nil)

    # Additional messages in various sections for more comprehensive test
    log.add("ERR14", xml.at("//title[@id='title1']")) # In intro - suppressed
    log.add("ERR15", xml.at("//para[@id='para3']")) # In sub1-p5 range -
    # suppressed
    log.add("ERR16", xml.at("//section[@id='sec2']")) # main section
    # but not in sub1-p5 - not suppressed
    log.add("ERR17", xml.at("//para[@id='para6']"))  # In conclusion
    log.add("ERR18", xml.at("//para[@id='para6']"))  # In conclusion
    log.add("ERR19", xml.at("//para[@id='para1']"))  # In intro - suppressed
    log.add("ERR20", xml.at("//para[@id='para4']"))  # In sub1-p5 range -
    # suppressed

    # Messages outside all suppressed ranges
    log.add("ERR21", "Outside location")
    log.add("ERR22", nil)

    # Set up location-based suppression
    log.suppress_log = {
      severity: 4,
      category: [],
      error_ids: [],
      locations: [
        { from: "intro" }, # Suppress all messages in intro section
        { from: "sub1", to: "p5" }, # Suppress all messages from sub1 to p5
        { from: "conclusion", error_ids: ["ERR08", "ERR09"] },
        # Suppress only ERR08 and ERR09 in conclusion
      ],
    }

    # Count messages before filtering
    expect(log.messages.length).to eq 22

    # No location filtering, no change in log
    FileUtils.rm_f("log.err.html")
    log.write("log.txt")
    expect(log.messages.length).to eq 22

    # Apply location filtering, as part of outputting log to disk
    log.add_error_ranges(xml)
    FileUtils.rm_f("log.err.html")
    log.write("log.txt")

    # Count messages after filtering
    total_after = log.messages.length

    # Expected to remain:
    # - ERR11, ERR12 (string locations)
    # - ERR13 (nil location)
    # - ERR10, ERR17, ERR18 (in conclusion but not in error_ids list)
    # - ERR16 (in main section but before sub1)
    # - ERR21, ERR22 (outside locations)
    expect(total_after).to eq 9

    # Verify specific messages are present
    remaining_error_ids = log.messages.map { |m| m[:error_id].to_s }
    expect(remaining_error_ids)
      .to include("ERR10", "ERR11", "ERR12", "ERR13",
                  "ERR16", "ERR17", "ERR18", "ERR21", "ERR22")

    # Verify specific messages were filtered out
    expect(remaining_error_ids)
      .not_to include("ERR01", "ERR02", "ERR03", "ERR14", "ERR19") # intro section
    expect(remaining_error_ids)
      .not_to include("ERR04", "ERR05", "ERR06", "ERR07", "ERR15", "ERR20")
    # sub1-p5 range
    expect(remaining_error_ids)
      .not_to include("ERR08", "ERR09") # conclusion with error_ids

    file = File.read("log.err.html", encoding: "utf-8")
    expect(file).to include("ERR10", "ERR11", "ERR12", "ERR13",
                            "ERR16", "ERR17", "ERR18", "ERR21", "ERR22")
    expect(file).not_to include("ERR01", "ERR02", "ERR03", "ERR14", "ERR19")
    expect(file).not_to include("ERR04", "ERR05", "ERR06", "ERR07", "ERR15",
                                "ERR20")
    expect(file).not_to include("ERR08", "ERR09")
  end
end
