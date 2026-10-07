require "spec_helper"

RSpec.describe Metanorma::Utils::AsciidoctorTableBuffer do
  it "is applied to Asciidoctor::Parser" do
    expect(described_class.applied?).to be true
  end

  it "prepends ParserContext#append_to_buffer and the skip helpers" do
    ctx = Asciidoctor::Table::ParserContext.instance_method(:append_to_buffer)
    expect(ctx.owner).to eq Asciidoctor::TableCellBufferParserContextPatch
    expect(Asciidoctor::Table::ParserContext.instance_method(:skip_past_delimiter).owner)
      .to eq Asciidoctor::TableCellBufferParserContextPatch
    # the stock readers drain the segments and delegate upward
    expect(Asciidoctor::Table::ParserContext.instance_method(:close_cell).owner)
      .to eq Asciidoctor::TableCellBufferParserContextPatch
    expect(Asciidoctor::Table::ParserContext.instance_method(:buffer_has_unclosed_quotes?).owner)
      .to eq Asciidoctor::TableCellBufferParserContextPatch
  end

  it "accumulates the content of a psv cell that spans multiple lines" do
    input = <<~'ADOC'
      [cols=1]
      |===
      |cell content
      and more
      and more again
      |next row
      |===
    ADOC
    table = Asciidoctor.load(input, standalone: false).blocks[0]
    expect(table.rows.body.size).to eq 2
    expect(table.rows.body[0][0].text).to eq %(cell content\nand more\nand more again)
    expect(table.rows.body[1][0].text).to eq "next row"
  end

  it "parses a psv cell followed by twenty thousand whitespace lines" do
    input = +"[cols=1]\n|===\n|cell\n" + ("  \n" * 20_000) + "|end\n|===\n"
    table = Asciidoctor.load(input, standalone: false).blocks[0]
    expect(table.rows.head[0][0].text).to eq "cell"
    expect(table.rows.body[0][0].text).to eq "end"
  end

  it "keeps quoted csv cell content" do
    input = <<~'ADOC'
      [format=csv]
      |===
      "a,b",c
      |===
    ADOC
    table = Asciidoctor.load(input, standalone: false).blocks[0]
    expect(table.rows.body[0][0].text).to eq "a,b"
    expect(table.rows.body[0][1].text).to eq "c"
  end

  it "keeps escaped delimiters at the end of the line" do
    input = <<~'ADOC'
      [%header,cols="1,1"]
      |===
      |A |B\|
      |A1 |B1\|
      |===
    ADOC
    table = Asciidoctor.load(input, standalone: false).blocks[0]
    expect(table.rows.body[0][1].text).to eq "B1|"
  end

  it "keeps cells intact when the csv quote check drains the segments mid-cell" do
    input = <<~'ADOC'
      [format=csv]
      |===
      "multi
      line",b
      c,d
      |===
    ADOC
    table = Asciidoctor.load(input, standalone: false).blocks[0]
    expect(table.rows.body[0][0].text).to eq "multi\nline"
    expect(table.rows.body[0][1].text).to eq "b"
    expect(table.rows.body[1][0].text).to eq "c"
    expect(table.rows.body[1][1].text).to eq "d"
  end

  it "renders the same html as the stock parser" do
    input = <<~'ADOC'
      [%header,cols="1,1"]
      |===
      |A |B
      |multi
      line |B1\|
      |===
    ADOC
    patched = Asciidoctor.convert(input, standalone: false)
    expect(patched).to include("<td class=\"tableblock halign-left valign-top\"><p class=\"tableblock\">multi\nline</p></td>")
    expect(patched).to include("<td class=\"tableblock halign-left valign-top\"><p class=\"tableblock\">B1|</p></td>")
  end

  describe "the stand-down detection" do
    let(:parser_path) { described_class::PARSER_FILE }

    it "stands down when upstream appends in place (append_to_buffer)" do
      described_class.instance_variable_set(:@applied, false)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(parser_path)
        .and_return('parser_ctx.append_to_buffer %(#{line}#{LF})')
      expect(described_class.apply!).to be false
    end

    it "stands down when upstream drops the per-line buffer rebuild" do
      described_class.instance_variable_set(:@applied, false)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(parser_path)
        .and_return("parser_ctx.buffer << line")
      expect(described_class.apply!).to be false
    end

    it "applies while the quadratic rebuild remains" do
      described_class.instance_variable_set(:@applied, false)
      expect(described_class.apply!).to be true
    end
  end
end
