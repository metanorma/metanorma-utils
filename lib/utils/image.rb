require "tempfile"
require "marcel"
require "base64"

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
        %r{^data:(image|application)/(?<imgtype>[^;]+);(charset=[^;]+;)?base64,(?<imgdata>.+)$} =~ uri
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
        if (i = svgmap.at(namespace.ns(".//image"))) && (src = i["src"])
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
      def datauri(uri, local_dir = ".")
        # Return the data URI if it already is a data URI
        return uri if datauri?(uri)

        # Return the URL if it is a URL
        return uri if url?(uri)

        local_path = uri
        relative_path = File.join(local_dir, uri)

        # Check whether just the local path or the other specified relative path
        # works.
        path = [local_path, relative_path].detect do |p|
          File.exist?(p) ? p : nil
        end

        unless path && File.exist?(path)
          warn "Image specified at `#{uri}` does not exist."
          # Return original provided location
          return uri
        end

        encode_datauri(path)
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
        %r{^([A-Z]:)?/}.match?(url)
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
    end
  end
end
