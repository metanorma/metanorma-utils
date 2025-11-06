require "spec_helper"
require_relative "../lib/utils/anchor_ranges"

RSpec.describe Metanorma::Utils::AnchorRanges do
  describe "#anchor_map" do
    it "generates map with linear order" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section id="sec1" anchor="a1">
            <title id="title1">Title</title>
            <para id="para1" anchor="a2">Text</para>
          </section>
          <section id="sec2" anchor="a3">
            <para id="para2">More text</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      expect(result.length).to eq 5
      expect(result[0][:id]).to eq "sec1"
      expect(result[0][:anchor]).to eq "a1"
      expect(result[0][:ord]).to eq 0
      expect(result[1][:id]).to eq "title1"
      expect(result[1][:ord]).to eq 1
      expect(result[2][:id]).to eq "para1"
      expect(result[2][:anchor]).to eq "a2"
      expect(result[2][:ord]).to eq 2
    end

    it "tracks next non-descendant anchor correctly" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section id="sec1" anchor="a1">
            <title id="title1">Title</title>
            <para id="para1" anchor="a2">Text</para>
          </section>
          <section id="sec2" anchor="a3">
            <para id="para2">More text</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      # sec1 should have next_anchor as a3 (skipping its children)
      expect(result[0][:next_anchor]).to eq "a3"

      # title1 has next sibling para1 with anchor a2
      expect(result[1][:next_anchor]).to eq "a2"

      # para1 should have next_anchor as a3 (next section after parent)
      expect(result[2][:next_anchor]).to eq "a3"

      # sec2 has no next non-descendant with anchor
      expect(result[3][:next_anchor]).to be_nil
    end

    it "handles nested structures correctly" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section anchor="s1">
            <subsection anchor="s1a">
              <para anchor="p1">Text</para>
            </subsection>
            <subsection anchor="s1b">
              <para anchor="p2">Text</para>
            </subsection>
          </section>
          <section anchor="s2">
            <para anchor="p3">Text</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      # s1 should skip all descendants and point to s2
      expect(result[0][:anchor]).to eq "s1"
      expect(result[0][:next_anchor]).to eq "s2"

      # s1a should point to s1b (next sibling)
      expect(result[1][:anchor]).to eq "s1a"
      expect(result[1][:next_anchor]).to eq "s1b"

      # p1 should point to s1b (next after parent)
      expect(result[2][:anchor]).to eq "p1"
      expect(result[2][:next_anchor]).to eq "s1b"

      # s1b should point to s2 (next after parent's siblings)
      expect(result[3][:anchor]).to eq "s1b"
      expect(result[3][:next_anchor]).to eq "s2"
    end

    it "handles nodes with only id attribute" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section id="sec1">
            <para id="para1">Text</para>
          </section>
          <section anchor="sec2">
            <para anchor="para2">Text</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      expect(result[0][:id]).to eq "sec1"
      expect(result[0][:anchor]).to be_nil
      expect(result[1][:id]).to eq "para1"
      expect(result[2][:anchor]).to eq "sec2"
      expect(result[3][:anchor]).to eq "para2"
    end

    it "handles nodes with both id and anchor attributes" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section id="sec1" anchor="a1">
            <para id="para1" anchor="a2">Text</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      expect(result[0][:id]).to eq "sec1"
      expect(result[0][:anchor]).to eq "a1"
      expect(result[1][:id]).to eq "para1"
      expect(result[1][:anchor]).to eq "a2"
    end

    it "handles document with no nodes having id or anchor" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section>
            <para>Text</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      expect(result).to be_empty
    end

    it "handles last node correctly (no next_anchor)" do
      doc = Nokogiri::XML(<<~XML)
        <root>
          <section anchor="s1">
            <para anchor="p1">Last para</para>
          </section>
        </root>
      XML

      ranges = Metanorma::Utils::AnchorRanges.new(doc)
      result = ranges.anchor_map

      # Last node should have nil next_anchor
      expect(result.last[:anchor]).to eq "p1"
      expect(result.last[:next_anchor]).to be_nil
    end
  end
end
