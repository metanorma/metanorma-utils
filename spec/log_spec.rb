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
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 1</h2>
      <table border="1">
      <thead><th width="10%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="40%">Context</th></thead>
      <tbody>
      <tr><th></th><th>--</th><td>Message 1</td><td><pre></pre></td></tr>
      <tr><th></th><th>node</th><td>Message 2</td><td><pre></pre></td></tr>
      </tbody></table>
      <h2>Category 2</h2>
      <table border="1">
      <thead><th width="10%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="40%">Context</th></thead>
      <tbody>
      <tr><th>000002</th><th>--</th><td>Message 4</td><td><pre>&lt;a&gt;
      &lt;b id=&quot;xyz&quot;&gt;
      c
      &lt;/b&gt; &lt;/a&gt;</pre></td></tr>
      <tr><th>000002</th><th>--</th><td>Message 5</td><td><pre>Context</pre></td></tr>
      <tr><th>000003</th><th><a href='log.txt#def'>ID def</a></th><td>Message 3</td><td><pre>&lt;b id=&quot;xyz&quot;&gt;
      c
      &lt;/b&gt;</pre></td></tr>
      </tbody></table>
      <h2>Category 3</h2>
      <table border="1">
      <thead><th width="10%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="40%">Context</th></thead>
      <tbody>
      <tr><th></th><th>--</th><td>Message 6.1</td><td><pre>ID: </pre></td></tr>
      <tr><th></th><th>--</th><td>Message 6.3</td><td><pre>ID: </pre></td></tr>
      <tr><th></th><th><a href='log.txt#B'>ID B</a></th><td>Message 6.2</td><td><pre>ID: B</pre></td></tr>
      </tbody></table>
      <h2>Category 4</h2>
      <table border="1">
      <thead><th width="10%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="40%">Context</th></thead>
      <tbody>
      <tr><th></th><th>??</th><td>Message 7.2</td><td><pre>Line: </pre></td></tr>
      <tr><th></th><th>??</th><td>Message 7.4</td><td><pre>Line: </pre></td></tr>
      <tr><th>000013</th><th>XML Line 000013</th><td>Message 7.3</td><td><pre>Line: 13</pre></td></tr>
      <tr><th>1212</th><th>Asciidoctor Line 000012</th><td>XML Line 1212:40, Message 7.1</td><td><pre>Line: 12</pre></td></tr>
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
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 1</h2>
      <table border="1">
      <thead><th width="10%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="40%">Context</th></thead>
      <tbody>
      <tr><th></th><th>--</th><td>é�</td><td><pre></pre></td></tr>
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
      <style> pre { white-space: pre-wrap; } </style>
      </head><body><h1>log.txt errors</h1>
      <h2>Category 2</h2>
      <table border="1">
      <thead><th width="10%">Line</th><th width="20%">ID</th><th width="30%">Message</th><th width="40%">Context</th></thead>
      <tbody>
      <tr><th>000002</th><th>--</th><td>Message 3</td><td><pre>&lt;a&gt;
      The number is &lt;latexmath&gt;\\1&lt;/latexmath&gt; &lt;/a&gt;</pre></td></tr>
      </tbody></table>
      </body></html>
    OUTPUT
  end
end
