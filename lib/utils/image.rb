require "tempfile"
require "marcel"
require "base64"
require "image_size"

module Metanorma
  module Utils
    class << self
      class Namespace
        def initialize(xmldoc)
          @namespace = xmldoc.root.namespace
        end

        def ns(path)
          return path if @namespace.nil?

          path.gsub(%r{/([a-zA-z])}, "/xmlns:\\1")
            .gsub(%r{::([a-zA-z])}, "::xmlns:\\1")
            .gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1")
            .gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]*\])}, "[xmlns:\\1")
        end
      end

      def save_dataimage(uri)
        %r{^data:(?:image|application)/(?<imgtype>[^;]+);(?:charset=[^;]+;)?base64,(?<imgdata>.+)$} =~ uri
        imgtype.sub!(/\+[a-z0-9]+$/, "") # svg+xml
        imgtype = "png" unless /^[a-z0-9]+$/.match? imgtype
        Tempfile.open(["image", ".#{imgtype}"]) do |f|
          f.binmode
          f.write(Base64.strict_decode64(imgdata))
          f.path
        end
      end

      SVG_NS = "http://www.w3.org/2000/svg".freeze

      def svgmap_rewrite(xmldoc, localdirectory = "")
        n = Namespace.new(xmldoc)
        xmldoc.xpath(n.ns("//svgmap")).each_with_index do |s, i|
          next unless svgmap_rewrite0(s, n, localdirectory, i)
          next if s.at(n.ns("./target/eref"))

          s.replace(s.at(n.ns("./figure")))
        end
      end

      def svgmap_rewrite0(svgmap, namespace, localdirectory, idx)
        if (i = svgmap.at(namespace.ns(".//image"))) &&
            (src = i["src"]) && !src.empty?
          path = svgmap_rewrite0_path(src, localdirectory)
          File.file?(path) or return false
          svg = Nokogiri::XML(File.read(path, encoding: "utf-8"))
          i.replace(svgmap_rewrite1(svgmap, svg.root, namespace, idx))
          /^data:/.match(src) and i["src"] = datauri(path)
        elsif i = svgmap.at(".//m:svg", "m" => SVG_NS)
          i.replace(svgmap_rewrite1(svgmap, i, namespace, idx))
        else return false
        end
        true
      end

      def svgmap_rewrite0_path(src, localdirectory)
        if /^data:/.match?(src)
          save_dataimage(src)
        else
          File.file?(src) ? src : localdirectory + src
        end
      end

      def svgmap_rewrite1(svgmap, svg, namespace, idx)
        svg_update_href(svgmap, svg, namespace)
        svg_update_ids(svg, idx)
        svg.xpath("processing-instruction()|.//processing-instruction()").remove
        svg.to_xml
      end

      def svg_update_href(svgmap, svg, namespace)
        targ = svgmap_rewrite1_targets(svgmap, namespace)
        svg.xpath(".//m:a", "m" => SVG_NS).each do |a|
          ["xlink:href", "href"].each do |p|
            a[p] and x = targ[File.expand_path(a[p])] and a[p] = x
          end
        end
      end

      def svgmap_rewrite1_targets(svgmap, namespace)
        svgmap.xpath(namespace.ns("./target"))
          .each_with_object({}) do |t, m|
          x = t.at(namespace.ns("./xref")) and
            m[File.expand_path(t["href"])] = "##{x['target']}"
          x = t.at(namespace.ns("./link")) and
            m[File.expand_path(t["href"])] = x["target"]
          t.remove if t.at(namespace.ns("./xref | ./link"))
        end
      end

      def svg_update_ids(svg, idx)
        ids = svg.xpath("./@id | .//@id")
          .each_with_object([]) { |i, m| m << i.value }
        return if ids.empty?

        svg_update_ids_attrs(svg, ids, idx)
        svg_update_ids_css(svg, ids, idx)
      end

      def svg_update_ids_attrs(svg, ids, idx)
        svg.xpath(". | .//*[@*]").each do |a|
          a.attribute_nodes.each do |x|
            ids.include?(x.value) and x.value += sprintf("_%09d", idx)
          end
        end
      end

      def svg_update_ids_css(svg, ids, idx)
        svg.xpath("//m:style", "m" => SVG_NS).each do |s|
          c = s.children.to_xml
          ids.each do |i|
            c = c.gsub(%r[##{i}\b],
                       sprintf("#%<id>s_%<idx>09d", id: i, idx: idx))
              .gsub(%r(\[id\s*=\s*['"]?#{i}['"]?\]),
                    sprintf("[id='%<id>s_%<idx>09d']", id: i, idx: idx))
          end
          s.children = c
        end
      end

      # sources/plantuml/plantuml20200524-90467-1iqek5i.png
      # already includes localdir
      # Check whether just the local path or the other specified relative path
      # works.
      def datauri(uri, local_dir = ".")
        (datauri?(uri) || url?(uri)) and return uri
        options = absolute_path?(uri) ? [uri] : [uri, File.join(local_dir, uri)]
        path = options.detect do |p|
          File.exist?(p) ? p : nil
        end
        path and return encode_datauri(path)
        warn "Image specified at `#{uri}` does not exist."
        uri # Return original provided location
      end

      def encode_datauri(path)
        return nil unless File.exist?(path)

        type = Marcel::MimeType.for(Pathname.new(path)) ||
          'text/plain; charset="utf-8"'

        bin = File.binread(path)
        data = Base64.strict_encode64(bin)
        "data:#{type};base64,#{data}"
      rescue StandardError
        warn "Data-URI encoding of `#{path}` failed."
        nil
      end

      def datauri?(uri)
        /^data:/.match?(uri)
      end

      def url?(url)
        %r{^[A-Z]{2,}://}i.match?(url)
      end

      def absolute_path?(uri)
        %r{^/}.match?(uri) || %r{^[A-Z]:/}.match?(uri)
      end

      def decode_datauri(uri)
        %r{^data:(?<mimetype>[^;]+);base64,(?<mimedata>.+)$} =~ uri
        return nil unless mimetype && mimedata

        data = Base64.strict_decode64(mimedata)
        {
          type_declared: mimetype,
          type_detected: Marcel::MimeType.for(data, declared_type: mimetype),
          data: data,
        }
      end

      # FIXME: This method should ONLY return 1 type, remove Array wrapper
      def datauri2mime(uri)
        output = decode_datauri(uri)
        return nil unless output && output[:type_detected]

        [output[:type_detected]]
      end

      def image_resize(img, path, maxheight, maxwidth)
        s, realsize = get_image_size(img, path)
        s.nil? and return [nil, nil]
        s[0] == nil && s[1] == nil and return s
        img.name == "svg" && !img["viewBox"] and
          img["viewBox"] = "0 0 #{s[0]} #{s[1]}"
        s = image_size_fillin(s, realsize)
        image_shrink(s, maxheight, maxwidth)
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
        elsif realsize.nil? || realsize[0].nil? || realsize[1].nil?
          dim = [nil, nil]
        end
        [dim, realsize]
      end
    end
  end
end
