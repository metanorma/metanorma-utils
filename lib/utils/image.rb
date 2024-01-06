require "tempfile"
require "marcel"
require "base64"
require "image_size"
require_relative "namespace"

module Metanorma
  module Utils
    class << self
      def image_resize(img, path, maxheight, maxwidth)
        s, realsize = get_image_size(img, path)
        img.name == "svg" && !img["viewBox"] && s[0] && s[1] and
          img["viewBox"] = "0 0 #{s[0]} #{s[1]}"
        s, skip = image_dont_resize(s, realsize)
        skip and return s
        s = image_size_fillin(s, realsize)
        image_shrink(s, maxheight, maxwidth)
      end

      def image_dont_resize(dim, realsize)
        dim.nil? and return [[nil, nil], true]
        realsize.nil? and return [dim, true]
        dim[0] == nil && dim[1] == nil and return [dim, true]
        [dim, false]
      end

      def image_size_fillin(dim, realsize)
        dim[1].zero? && !dim[0].zero? and
          dim[1] = dim[0] * realsize[1] / realsize[0]
        dim[0].zero? && !dim[1].zero? and
          dim[0] = dim[1] * realsize[0] / realsize[1]
        dim
      end

      def image_shrink(dim, maxheight, maxwidth)
        dim[1] > maxheight and
          dim = [(dim[0] * maxheight / dim[1]).ceil, maxheight]
        dim[0] > maxwidth and
          dim = [maxwidth, (dim[1] * maxwidth / dim[0]).ceil]
        dim
      end

      def get_image_size(img, path)
        realsize = ImageSize.path(path).size
        s = image_size_interpret(img, realsize || [nil, nil])
        image_size_zeroes_complete(s, realsize)
      end

      def image_size_interpret(img, realsize)
        w = image_size_percent(img["width"], realsize[0])
        h = image_size_percent(img["height"], realsize[1])
        [w, h]
      end

      def image_size_percent(value, real)
        /%$/.match?(value) && !real.nil? and
          value = real * (value.sub(/%$/, "").to_f / 100)
        value.to_i
      end

      def image_size_zeroes_complete(dim, realsize)
        if dim[0].zero? && dim[1].zero?
          dim = realsize
        end
        [dim, realsize]
      end
    end
  end
end
