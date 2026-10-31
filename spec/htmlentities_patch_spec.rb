# frozen_string_literal: true

require "spec_helper"
require "metanorma-utils"

RSpec.describe Metanorma::Utils::HTMLEntitiesEncoderCache do
  subject(:coder) { HTMLEntities.new }

  it "matches vanilla htmlentities output for every instruction set" do
    vanilla = HTMLEntities.new
    samples = [
      "plain ascii",
      "café <tag> & 'quote' \"double\" — em dash ©℗",
      "a < b && c > d",
      "émoji 🎛 and ελληνικά",
    ]
    instruction_sets = [
      [],
      [:basic],
      [:basic, :named],
      [:basic, :decimal],
      [:basic, :hexadecimal],
      [:named, :decimal],
      [:hexadecimal, :basic],
    ]
    instruction_sets.each do |set|
      samples.each do |sample|
        expect(coder.encode(sample, *set)).to eq(vanilla.encode(sample, *set))
      end
    end
  end

  it "rejects invalid instructions like vanilla" do
    expect { coder.encode("x", :bogus) }
      .to raise_error(HTMLEntities::InstructionError)
  end

  it "keeps producing stable output across repeated encodes" do
    sample = "café <tag> & 'quote' — ©"
    first = coder.encode(sample, :basic, :hexadecimal)
    expect(Array.new(100) { coder.encode(sample, :basic, :hexadecimal) }
      .uniq).to eq([first])
  end
end
