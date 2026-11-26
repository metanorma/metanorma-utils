# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Utils do
  describe ".stable_uuid" do
    it "returns a UUID string" do
      expect(Metanorma::Utils.stable_uuid("doc", "Scope"))
        .to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end

    it "is deterministic: the same parts produce the same UUID" do
      a = Metanorma::Utils.stable_uuid("doc", "Scope", 1)
      b = Metanorma::Utils.stable_uuid("doc", "Scope", 1)
      expect(a).to eq(b)
    end

    it "differs when any part differs" do
      a = Metanorma::Utils.stable_uuid("doc", "Scope", 1)
      b = Metanorma::Utils.stable_uuid("doc", "Scope", 2)
      c = Metanorma::Utils.stable_uuid("other", "Scope", 1)
      expect(a).not_to eq(b)
      expect(a).not_to eq(c)
    end

    it "is a UUIDv5 (version nibble 5)" do
      uuid = Metanorma::Utils.stable_uuid("doc", "Scope")
      expect(uuid.split("-")[2][0]).to eq("5")
    end
  end
end
