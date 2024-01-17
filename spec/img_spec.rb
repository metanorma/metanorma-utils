require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Utils do
  describe ".create_namespace" do
    it "creates Namespace object" do
      Metanorma::Utils.create_namespace(Nokogiri.parse(<<~XML)).ns("")
        <root xmlns="http://nokogiri.org/ns/default"></root>
      XML
    end
  end
end
