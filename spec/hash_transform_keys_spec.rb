require "spec_helper"
require "utils/hash_transform_keys"

RSpec.describe Metanorma::Utils do
  it "deep stringify hash but skip values" do
    Hash.include Metanorma::Utils::Hash
    Array.include Metanorma::Utils::Array
    result = {
      test0: :test0,
      test1: false,
      test2: {
        test20: :test20,
      },
      test3: %i(test31 test32 test33),
      test4: [
        {
          test41: :test41,
        },
      ],
    }.stringify_all_keys

    expect(result).to include("test0", "test1", "test2", "test3", "test4")
    expect(result["test0"]).to eq(:test0)
    expect(result["test2"]).to include("test20")
    expect(result["test2"]["test20"]).to eq(:test20)
    expect(result["test3"]).to include(:test31, :test32, :test33)
    expect(result["test4"][0]).to include("test41")
    expect(result["test4"][0]["test41"]).to eq(:test41)
  end

  it "deep symbolize hash but skip values" do
    Hash.include Metanorma::Utils::Hash
    Array.include Metanorma::Utils::Array
    result = {
      test0: "test0",
      test1: false,
      test2: {
        test20: "test20",
      },
      test3: %w(test31 test32 test33),
      test4: [
        {
          test41: "test41",
        },
      ],
    }.stringify_all_keys.symbolize_all_keys

    expect(result).to include(:test0, :test1, :test2, :test3, :test4)
    expect(result[:test0]).to eq("test0")
    expect(result[:test2]).to include(:test20)
    expect(result[:test2][:test20]).to eq("test20")
    expect(result[:test3]).to include("test31", "test32", "test33")
    expect(result[:test4][0]).to include(:test41)
    expect(result[:test4][0][:test41]).to eq("test41")
  end

  it "deep merges hashes" do
    Hash.include Metanorma::Utils::Hash
    hash1 = { a: [1, 2], b: "c", c: 4, e: { f: { g: "1" } }, i: 6 }
    hash2 = { a: [3], b: "d", d: 5, e: { f: { h: "2" } }, i: nil }
    expect(hash1.deep_merge(hash2))
      .to eq({ a: [1, 2, 3], b: "d", c: 4,
               d: 5, e: { f: { g: "1", h: "2" } }, i: nil })
  end
end
