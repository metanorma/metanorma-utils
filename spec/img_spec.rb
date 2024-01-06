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

  it "resizes images with missing or auto sizes" do
    image = Nokogiri::XML("<img src='spec/19160-8.jpg'/>").root
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "20"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [20, 65]
    image.delete("width")
    image["height"] = "50"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [15, 50]
    image.delete("height")
    image["width"] = "500"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image.delete("width")
    image["height"] = "500"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "20"
    image["height"] = "auto"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [20, 65]
    image["width"] = "auto"
    image["height"] = "50"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [15, 50]
    image["width"] = "500"
    image["height"] = "auto"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "auto"
    image["height"] = "500"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
    image["width"] = "auto"
    image["height"] = "auto"
    expect(Metanorma::Utils.image_resize(image, "spec/19160-8.jpg", 100, 100))
      .to eq [30, 100]
  end

  it "converts percentage sizes of images" do
    image = Nokogiri::XML("<img src='spec/19160-8.jpg'/>").root
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[919, 3000], [919, 3000]]
    image["width"] = "20.4"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[20, 0], [919, 3000]]
    image["height"] = "auto"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[20, 0], [919, 3000]]
    image.delete("width")
    image["height"] = "20.4"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[0, 20], [919, 3000]]
    image["width"] = "auto"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[0, 20], [919, 3000]]
    image["height"] = "30%"
    image["width"] = "50%"
    expect(Metanorma::Utils.get_image_size(image, "spec/19160-8.jpg"))
      .to eq [[459, 900], [919, 3000]]
  end

  it "resizes SVG with missing or auto sizes" do
    image = Nokogiri::XML(File.read("spec/odf.svg")).root
    Metanorma::Utils.image_resize(image, "spec/odf.svg", 100, 100)
    expect(image.attributes["viewBox"].value).to eq "0 0 100 100"
  end
end
