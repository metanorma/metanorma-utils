require "spec_helper"
require_relative "../lib/utils/anchor_ranges"

RSpec.describe Metanorma::Utils::AnchorRanges do
  let(:doc) do
    Nokogiri::XML(<<~XML)
      <document>
        <section id="sec1" anchor="intro">
          <title id="title1">Introduction</title>
          <para id="para1" anchor="p1">First paragraph</para>
          <para id="para2">Second paragraph</para>
        </section>
        <section id="sec2" anchor="main">
          <subsection id="subsec1" anchor="sub1">
            <para id="para3">Nested paragraph</para>
          </subsection>
          <para id="para4" anchor="p2">Final paragraph</para>
        </section>
        <section id="sec3" anchor="conclusion">
          <para id="para5">Last paragraph</para>
        </section>
      </document>
    XML
  end

  let(:ranges) { Metanorma::Utils::AnchorRanges.new(doc) }

  describe "#anchor_map" do
    it "memoizes the anchor_map" do
      map1 = ranges.anchor_map
      map2 = ranges.anchor_map
      expect(map1.object_id).to eq map2.object_id
    end

    it "returns the correct map" do
      map = ranges.anchor_map
      expect(map.first[:anchor]).to eq "intro"
      expect(map.first[:id]).to eq "sec1"
    end
  end

  describe "#anchor_to_ord" do
    it "maps anchors to ordinals" do
      mapping = ranges.anchor_to_ord
      expect(mapping["intro"]).to eq 0
      expect(mapping["p1"]).to eq 2
      expect(mapping["main"]).to eq 4
    end
  end

  describe "#id_to_ord" do
    it "maps ids to ordinals" do
      mapping = ranges.id_to_ord
      expect(mapping["sec1"]).to eq 0
      expect(mapping["para1"]).to eq 2
      expect(mapping["sec2"]).to eq 4
    end
  end

  describe "#anchor_to_last_ord" do
    it "maps anchors to last descendant ordinals" do
      mapping = ranges.anchor_to_last_ord
      # intro section ends before main section starts
      expect(mapping["intro"]).to eq 3 # para2 is the last child
      # main section ends before conclusion starts
      expect(mapping["main"]).to eq 7 # para4 is the last child
      # conclusion has no next anchor, so extends to end
      expect(mapping["conclusion"]).to eq 9 # para5 is last
    end
  end

  describe "#in_range?" do
    it "returns true when node is within range (same section)" do
      # para1 is within intro-intro range
      expect(ranges.in_range?("para1", "intro", "intro")).to be true
      # para2 is within intro-intro range
      expect(ranges.in_range?("para2", "intro", "intro")).to be true
      expect(ranges.in_range?("sec2", "intro", "intro")).to be false
    end

    it "returns true when node is at start of range" do
      # intro section itself is within intro-intro range
      expect(ranges.in_range?("intro", "intro", "intro")).to be true
      expect(ranges.in_range?("sec1", "intro", "intro")).to be true
    end

    it "returns true when node is at end of range" do
      # main section is within intro-main range
      expect(ranges.in_range?("main", "intro", "main")).to be true
    end

    it "returns true when node is within multi-section range" do
      # para1 is within intro-main range
      expect(ranges.in_range?("para1", "intro", "main")).to be true
      # para3 (in subsection of main) is within intro-main range
      expect(ranges.in_range?("para3", "intro", "main")).to be true
      # para4 (last in main) is within intro-main range
      expect(ranges.in_range?("para4", "intro", "main")).to be true
      expect(ranges.in_range?("para3", "intro", "p2")).to be true
      expect(ranges.in_range?("para3", "main", "conclusion")).to be true
    end

    it "returns false when node is before range" do
      # para1 is not in main-conclusion range
      expect(ranges.in_range?("para1", "main", "conclusion")).to be false
    end

    it "returns false when node is after range" do
      # para5 is not in intro-main range
      expect(ranges.in_range?("para5", "intro", "main")).to be false
    end

    it "works with node ids" do
      # Check using id instead of anchor
      expect(ranges.in_range?("sec1", "intro", "main")).to be true
      expect(ranges.in_range?("para2", "intro", "intro")).to be true
      expect(ranges.in_range?("para5", "intro", "main")).to be false
    end

    it "handles nested structures correctly" do
      # para3 is nested in subsection, which is in main
      expect(ranges.in_range?("para3", "main", "main")).to be true
      expect(ranges.in_range?("para3", "sub1", "sub1")).to be true
      expect(ranges.in_range?("subsec1", "main", "main")).to be true
    end

    it "returns false for non-existent anchors" do
      expect(ranges.in_range?("para1", "nonexistent", "intro")).to be false
      expect(ranges.in_range?("para1", "intro", "nonexistent")).to be false
      expect(ranges.in_range?("nonexistent", "intro", "main")).to be false
    end
  end

  describe "#anchor_range" do
    it "returns the ordinal range for an anchor" do
      range = ranges.anchor_range("intro")
      expect(range).to eq(0..3)
    end

    it "returns range including all descendants" do
      range = ranges.anchor_range("main")
      expect(range).to eq(4..7)
    end

    it "returns nil for non-existent anchor" do
      range = ranges.anchor_range("nonexistent")
      expect(range).to be_nil
    end
  end

  describe "complex range scenarios" do
    it "handles overlapping parent-child ranges correctly" do
      # p1 is within intro, sub1 is within main
      expect(ranges.in_range?("p1", "intro", "sub1")).to be true
      # para3 is nested in sub1
      expect(ranges.in_range?("para3", "intro", "sub1")).to be true
      # para4 comes after sub1
      expect(ranges.in_range?("para4", "intro", "sub1")).to be false
    end

    it "handles reverse order anchors (B before A) correctly" do
      # When B comes before A, no nodes should be in range
      # This is because start_ord > end_ord
      expect(ranges.in_range?("para1", "main", "intro")).to be false
      expect(ranges.in_range?("para3", "main", "intro")).to be false
    end
  end

  describe "performance characteristics" do
    it "builds hash lookups only once" do
      # First call builds the hashes
      ranges.in_range?("para1", "intro", "main")

      # Subsequent calls should use cached hashes
      expect(ranges).not_to receive(:build_anchor_to_ord)
      expect(ranges).not_to receive(:build_id_to_ord)
      expect(ranges).not_to receive(:build_anchor_to_last_ord)

      ranges.in_range?("para2", "intro", "main")
      ranges.in_range?("para3", "main", "conclusion")
    end
  end
end
