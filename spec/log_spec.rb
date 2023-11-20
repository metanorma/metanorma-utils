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
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", nil, "Message 1")
    log.add("Category 1", "node", "Message 2")
    log.add("Category 2", xml.at("//xml/a/b"), "Message 3")
    log.add("Category 2", xml.at("//xml/a"), "Message 4")
    log.add("Category 2", xml.at("//xml/a"), "Message 5 :: Context")
    log.add("Category 3", id1, "Message 6.1")
    log.add("Category 3", id2, "Message 6.2")
    log.add("Category 3", id3, "Message 6.3")
    log.add("Category 4", li1, "XML Line 1212:40, Message 7.1")
    log.add("Category 4", li2, "Message 7.2")
    log.add("Category 4", li3, "Message 7.3")
    log.add("Category 4", li4, "Message 7.4")
    log.mapid("xyz", "abc")
    log.mapid("abc", "def")
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to eq <<~OUTPUT
      <html><head><title>log.txt errors</title>
      <meta charset="UTF-8"/>
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 1</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code>--</code></th><td>Message 1</td><td><pre></pre></td></tr>
      <tr><td></td><th><code>node</code></th><td>Message 2</td><td><pre></pre></td></tr>
      </tbody></table>
      <h2>Category 2</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td>000002</td><th><code>--</code></th><td>Message 4</td><td><pre>&lt;a&gt;
      &lt;b id=&quot;xyz&quot;&gt;
      c
      &lt;/b&gt; &lt;/a&gt;</pre></td></tr>
      <tr><td>000002</td><th><code>--</code></th><td>Message 5</td><td><pre>Context</pre></td></tr>
      <tr><td>000003</td><th><code><a href='log.txt#def'>def</a></code></th><td>Message 3</td><td><pre>&lt;b id=&quot;xyz&quot;&gt;
      c
      &lt;/b&gt;</pre></td></tr>
      </tbody></table>
      <h2>Category 3</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code>--</code></th><td>Message 6.1</td><td><pre>ID: </pre></td></tr>
      <tr><td></td><th><code>--</code></th><td>Message 6.3</td><td><pre>ID: </pre></td></tr>
      <tr><td></td><th><code><a href='log.txt#B'>B</a></code></th><td>Message 6.2</td><td><pre>ID: B</pre></td></tr>
      </tbody></table>
      <h2>Category 4</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code>??</code></th><td>Message 7.2</td><td><pre>Line: </pre></td></tr>
      <tr><td></td><th><code>??</code></th><td>Message 7.4</td><td><pre>Line: </pre></td></tr>
      <tr><td>000013</td><th><code>XML Line 000013</code></th><td>Message 7.3</td><td><pre>Line: 13</pre></td></tr>
      <tr><td>1212</td><th><code>Asciidoctor Line 000012</code></th><td>XML Line 1212:40, Message 7.1</td><td><pre>Line: 12</pre></td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end

  it "suppresses syntax errors from screen display" do
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    expect { log.add("Category 1", nil, "A") }
      .to output("Category 1: A\n").to_stderr
    expect { log.add("Metanorma XML Syntax", nil, "A") }
      .not_to output("Metanorma XML Syntax: A\n").to_stderr
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to eq <<~OUTPUT
      <html><head><title>log.txt errors</title>
      <meta charset="UTF-8"/>
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 1</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code>--</code></th><td>A</td><td><pre></pre></td></tr>
      </tbody></table>
      <h2>Metanorma XML Syntax</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code>--</code></th><td>A</td><td><pre></pre></td></tr>
      </tbody></table>
      </body></html>
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
      <html><head><title>log.txt errors</title>
      <meta charset="UTF-8"/>
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 1</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code>--</code></th><td>é�</td><td><pre></pre></td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end

  it "deals with long strings in log" do
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    log.add("Category 1", "ID AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB")
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to eq <<~OUTPUT
      <html><head><title>log.txt errors</title>
      <meta charset="UTF-8"/>
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 1</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td></td><th><code><a href='log.txt#AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'>AAAAAAAAAAAAAAAAAAAA­AAAAAAAAAAAAAAAAAAAA­AAAAAAAAAAAAAA</a></code></th><td>BBBBBBBBBBBBBBBBBBBB­BBBBBBBBBBBBBBBBBBBB­BBBBBBBB</td><td><pre></pre></td></tr>
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
    FileUtils.rm_f("log.txt")
    log = Metanorma::Utils::Log.new
    log.add("Category 2", xml.at("//xml/a"), "Message 3")
    log.write("log.txt")
    expect(File.exist?("log.txt")).to be true
    file = File.read("log.txt", encoding: "utf-8")
    expect(file).to be_equivalent_to <<~OUTPUT
      <html><head><title>log.txt errors</title>
      <meta charset="UTF-8"/>
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 2</h2>
      <table border="1">
      <thead><th width="5%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="45%">Context</th></thead>
      <tbody>
      <tr><td>000002</td><th><code>--</code></th><td>Message 3</td><td><pre>&lt;a&gt;
      The number is &lt;latexmath&gt;\\1&lt;/latexmath&gt; &lt;/a&gt;</pre></td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end
end
