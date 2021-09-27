require "asciidoctor"
require "tempfile"
require "marcel"
require "mime/types"
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
            c = c.gsub(%r[##{i}\b], sprintf("#%s_%09d", i, idx))
              .gsub(%r(\[id\s*=\s*['"]?#{i}['"]?\]), sprintf("[id='%s_%09d']", i, idx))
          end
          s.children = c
        end
      end

      # sources/plantuml/plantuml20200524-90467-1iqek5i.png
      # already includes localdir
      def datauri(uri, localdirectory = ".")
        return uri if /^data:/.match?(uri)

        path = datauri_path(uri, localdirectory)
        return path unless File.exist?(path)

        types = MIME::Types.type_for(path)
        type = types ? types.first.to_s : 'text/plain; charset="utf-8"'
        bin = File.open(path, "rb", &:read)
        data = Base64.strict_encode64(bin)
        "data:#{type};base64,#{data}"
      end

      def datauri_path(uri, localdirectory)
        path = if %r{^([A-Z]:)?/}.match?(uri) then uri
               else
                 File.exist?(uri) ? uri : File.join(localdirectory, uri)
               end
        unless File.exist?(path)
          warn "image at #{path} not found"
          return uri
        end
        path
      end

      def datauri2mime(uri)
        %r{^data:image/(?<imgtype>[^;]+);base64,(?<imgdata>.+)$} =~ uri
        type = nil
        imgtype = "png" unless /^[a-z0-9]+$/.match? imgtype
        ::Tempfile.open(["imageuri", ".#{imgtype}"]) do |file|
          type = datauri2mime1(file, imgdata)
        end
        [type]
      end

      def datauri2mime1(file, imgdata)
        type = nil
        begin
          file.binmode
          file.write(Base64.strict_decode64(imgdata))
          file.rewind
          type = Marcel::MimeType.for file
        ensure
          file.close!
        end
        type
      end
    end
  end
end
