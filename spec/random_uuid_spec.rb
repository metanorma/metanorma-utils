# frozen_string_literal: true

require "spec_helper"
require "metanorma-utils"

RSpec.describe Metanorma::Utils do
  describe "#random_uuid" do
    it "returns a v4-shaped UUID string" do
      uuid = described_class.random_uuid
      expect(uuid).to match(
        /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/,
      )
    end

    it "sets the v4 version and variant bits" do
      bytes = described_class.random_uuid.delete("-").to_i(16)
        .to_s(16).rjust(32, "0")
      expect(bytes[12]).to eq("4")
    end

    it "draws unique identifiers across pool refills" do
      uuids = Array.new(100_000) { described_class.random_uuid }
      expect(uuids.uniq.size).to eq(uuids.size)
    end
  end
end
