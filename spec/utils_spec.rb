require "spec_helper"

RSpec.describe Metanorma::Utils do
  it "has a version number" do
    expect(Metanorma::Utils::VERSION).not_to be nil
  end

  it "normalises anchors" do
    expect(Metanorma::Utils.to_ncname("/:ab")).to eq "__ab"
  end
end
